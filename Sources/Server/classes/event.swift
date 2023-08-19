//
//  event.swift
//  faggot server
//
//  Created by Дмитрий Козлов on 07/03/16.
//  Copyright © 2016 anus. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class Event {
  static var version = 0
  
  //MARK:- main properties
  var id = Int()
  var name = String()
  var startTime = Time()
  var endTime = Time()
  var lat = Float()
  var lon = Float()
  var previewVersion = EventPreviewVersion()
  var lastContent: Content?
  
  private func loadMain(data: DataReader) throws {
    id = try data.next()
    name = try data.next()
    startTime = try data.next()
    endTime = try data.next()
    lat = try data.next()
    lon = try data.next()
    previewVersion = try data.next()
  }
  private func saveMain(data: DataWriter) {
    data.append(id)
    data.append(name)
    data.append(startTime)
    data.append(endTime)
    data.append(lat)
    data.append(lon)
    data.append(previewVersion)
  }
  
  //MARK:- public properties
  var owner = Int()
  var _status = EventStatus.started
  var privacy = EventPrivacy.public
  var options = EventOptions.Set()
  var createdTime = Time()
  
  var counter = Counter<ID>()
  var content = [ID: Content]()
  var comments: Comments
  var invited = Set<Int>()
  var views = Int()
  var current = Int()
  
  private func loadPublic(data: DataReader) throws {
    owner = try data.next()
    _status = try data.next()
    privacy = try data.next()
    options = try data.next()
    createdTime = try data.next()
    
    counter = try data.next()
    var last = -1
    let count = try data.int()
    for _ in 0..<count {
      let c = try data.content()
      content[c.id] = c
      if c.id > last {
        last = c.id
        lastContent = c
      }
    }
    invited = try data.next()
    views = try data.next()
    current = try data.next()
  }
  private func savePublic(data: DataWriter) {
    data.append(owner)
    data.append(_status)
    data.append(privacy)
    data.append(options)
    data.append(createdTime)
    
    data.append(counter)
    data.append(content.count)
    for c in content.values {
      data.append(c.type)
      data.append(c)
    }
    data.append(invited)
    data.append(views)
    data.append(current)
  }
  
  //MARK:- private properties
  var banlist = Set<Int>()
  
  private func loadPrivate(data: DataReader) throws {
    banlist = try data.next()
  }
  private func savePrivate(data: DataWriter) {
    data.append(banlist)
  }
  
  // server
  var subs = Set<Connection>()
  
  
  ///////////////////////
  // MARK:- Init
  ///////////////////////
  
  init(id: Int, name: String, owner: Int) {
    self.id = id
    self.name = name
    self.owner = owner
    createdTime = .now
    _status = .started
    
    self.invited.insert(owner)
    comments = Comments(id: id)
  }
  
  init(data: DataReader) throws {
    comments = try data.next()
    try loadMain(data: data)
    try loadPublic(data: data)
    try loadPrivate(data: data)
  }
  func save(data: DataWriter) {
    data.append(comments)
    saveMain(data: data)
    savePublic(data: data)
    savePrivate(data: data)
  }
  
  
  ///////////////////////
  // MARK:- Owner functions
  ///////////////////////
  
  func rename(_ owner: User, name: String, notify: Bool) throws {
    try check(owner: owner)
    self.name = name
    nextPreviewVersion()
    if notify {
      serverEvents.eventRenamed(event: self)
    }
  }
  
  func remove(by owner: User, user: User, notify: Bool) throws {
    try check(owner: owner)
    var add = false
    var ownerChanged = false
    defer {
      if notify && add {
        serverEvents.uninvite(event: self, user: user)
        if ownerChanged {
          serverEvents.ownerChanged(event: self)
        }
      }
    }
    if invited.count == 1 {
      isRemoved = true
    } else {
      if user.id == self.owner {
        for id in invited where user.id != id {
          self.owner = id
          ownerChanged = true
          break
        }
      }
      add = true
    }
    user.events.remove(self.id)
    user.publicProfileVersion.increment()
    invited.remove(user.id)
    map.eventRemoved(event: self)
  }
  func ban(_ owner: User, user: User, notify: Bool) throws {
    try check(invited: user)
    if invited.contains(user.id) {
      try! self.remove(by: owner, user: user, notify: notify)
    }
    banlist.insert(user.id)
  }
//  func delete(by owner: User, notify: Bool) throws {
//    try check(owner: owner)
//    isRemoved = true
//  }
  
  func set(status: EventStatus, notify: Bool) {
    _status = status
    if status == .ended {
      endTime = .now
      map.eventEnded(event: self)
    } else if status == .started {
      let now = Time.now
      if startTime > now {
        startTime = now
        endTime = now + .hour * 2
      }
    }
    nextPreviewVersion()
    if notify {
      serverEvents.eventStatus(event: self)
    }
  }
  func set(privacy: EventPrivacy, notify: Bool) {
    self.privacy = privacy
    nextPreviewVersion()
    map.eventPrivacyChanged(event: self)
    if notify {
      serverEvents.eventPrivacy(event: self)
    }
  }
  
  func nextPreviewVersion() {
    previewVersion.increment()
    invited.users.forEach { $0.publicProfileVersion.increment() }
  }
  
  
  ///////////////////////
  // MARK:- Invited functions
  ///////////////////////
  
  func invite(by inviter: User, user: User, notify: Bool) throws {
    try check(invited: inviter)
    guard !self.invited.contains(user.id) else { return }
    self.invited.insert(user.id)
    user.events.insert(self.id)
    user.publicProfileVersion.increment()
    if notify {
      serverEvents.invite(event: self, user: user, by: inviter)
    }
  }
  func newPhoto(author: Int, photoData: PhotoData, notify: Bool, from: Connection?) -> PhotoContent {
    let content = PhotoContent(id: counter.next(), author: author)
    content.photoData = photoData
    add(content: content, notify: notify, from: from)
    return content
  }
  func newVideo(author: Int, notify: Bool, from: Connection?) -> VideoContent {
    let content = VideoContent(id: counter.next(), author: author)
    add(content: content, notify: notify, from: from)
    return content
  }
  func add(content: Content, notify: Bool, from: Connection?) {
    if status != .ended {
      endTime = .now + .hour * 2
    }
    self.content[content.id] = content
    if notify {
      serverEvents.newContent(event: self, content: content, ignore: from)
    }
  }
  func remove(content id: Int, by user: User, notify: Bool) throws {
    try check(invited: user)
    if let c = content[id] {
      content[id] = nil
      if notify {
        serverEvents.contentRemoved(event: self, content: c)
      }
      if let last = lastContent, last.id == id {
        lastContent = content.values.max { $0.id < $1.id }
        nextPreviewVersion()
        if let last = lastContent {
          serverEvents.previewChanged(event: self, content: last)
        } else {
          serverEvents.previewRemoved(event: self)
        }
      }
    }
  }
  func set(preview: Content) {
    self.lastContent = preview
    nextPreviewVersion()
  }
  func canUploadPhoto(_ user: User, photo: Int) -> Bool {
    return isInvited(user) && content[photo] != nil
  }
  func set(status: EventStatus, by user: User, notify: Bool) throws {
    try check(owner: user)
    switch self.status {
    case .paused, .started:
      set(status: status, notify: notify)
    default:
      break
    }
  }
  func optionsChanged() {
    nextPreviewVersion()
  }
  
  
  ///////////////////////
  // MARK:- Visitor functions
  ///////////////////////
  
  func visit(user: User, notify: Bool) {
    if !user.views.contains(id) {
      user.views.insert(id)
      views += 1
      if notify {
        serverEvents.eventViews(event: self)
      }
    }
    current += 1
    if notify {
      serverEvents.eventCurrent(event: self)
    }
  }
  
  func unvisit(user: User, notify: Bool) {
    current -= 1
    if notify {
      serverEvents.eventCurrent(event: self)
    }
  }
  
  func view(by user: User) -> Bool {
    if !user.views.contains(id) {
      user.views.insert(id)
      views += 1
      return true
    }
    return false
  }
  
  
  ///////////////////////
  // MARK:- Utility functions
  ///////////////////////
  func check(owner user: User) throws {
    guard user.id == owner else { throw Response.eventPermissions }
  }
  func check(invited user: User) throws {
    guard invited.contains(user.id) else { throw Response.eventPermissions }
  }
  func check(banned user: User) throws {
    guard !banlist.contains(user.id) else { throw Response.eventPermissions }
  }
  func check(privacy user: User) throws {
    guard !isPrivate(for: user) else { throw Response.eventPermissions }
  }
  
  func isOwner(_ user: User) -> Bool {
    return user.id == owner
  }
  func isInvited(_ user: User) -> Bool {
    return user.id == owner || invited.contains(user.id)
  }
  func isBanned(_ user: User) -> Bool {
    return banlist.contains(user.id)
  }
  func canViewPhotos(_ user: User) -> Bool {
    return isPrivate(for: user)
  }
  func canViewVideos(_ user: User) -> Bool {
    return isPrivate(for: user)
  }
  func isPrivate(for user: User) -> Bool {
    switch privacy {
    case .open:
      return false
    case .public:
      return false
    case .subscribers:
      return !(invited.contains(user.id) || user.friends.intersection(invited).count > 0 || user.subscriptions.intersection(invited).count > 0)
    case .friends:
      return !(invited.contains(user.id) || user.friends.intersection(invited).count > 0)
    case .private:
      return !invited.contains(user.id)
    }
  }
}

/// Setters
extension Event {
  var status: EventStatus {
    if _status == .paused || _status == .started {
      if endTime < .now {
        _status = .ended
        map.eventEnded(event: self)
        serverEvents.eventStatus(event: self)
      }
    }
    return _status
  }
  
  var isOnline: Bool {
    get {
      return options[.online]
    } set {
      options[.online] = newValue
      optionsChanged()
    }
  }
  var isOnMap: Bool {
    get {
      return options[.onMap]
    } set {
      options[.onMap] = newValue
      optionsChanged()
    }
  }
  var isRemoved: Bool {
    get {
      return options[.removed]
    } set {
      options[.removed] = newValue
      optionsChanged()
    }
  }
  var isBanned: Bool {
    get {
      return options[.banned]
    } set {
      options[.banned] = newValue
      optionsChanged()
    }
  }
  var isProtected: Bool {
    get {
      return options[.protected]
    } set {
      options[.protected] = newValue
      optionsChanged()
    }
  }
}

extension ID {
  var event: Event! {
    return events[self]
  }
  var eventName: String {
    var a = "\(self)"
    if let event = event {
      a += " \(event.name)"
    }
    return a
  }
  func eventVersion(data: DataWriter) {
    events[self]!.eventVersion(data: data)
  }
  func eventMain(data: DataWriter) {
    events[self]!.eventMain(data: data)
  }
}

extension Sequence where Iterator.Element == Event {
  var ids: [Int] { return map { $0.id } }
  func eventVersion(data: DataWriter) {
    data.append(underestimatedCount)
    forEach { $0.eventVersion(data: data) }
  }
  func eventMain(data: DataWriter) {
    data.append(underestimatedCount)
    forEach { $0.eventMain(data: data) }
  }
}

extension Sequence where Iterator.Element == Int {
  var events: [Event] { return map { Events.shared[$0]! } }
  func eventVersion(data: DataWriter) {
    data.append(underestimatedCount)
    forEach { $0.eventVersion(data: data) }
  }
  func eventMain(data: DataWriter) {
    data.append(underestimatedCount)
    forEach { $0.eventMain(data: data) }
  }
}

extension Event {
  func eventVersion(data: DataWriter) {
    data.append(id)
    data.append(previewVersion)
  }
  func eventMain(data: DataWriter) {
    data.append(id)
    data.append(name)
    data.append(startTime)
    data.append(endTime)
    data.append(status)
    data.append(lat)
    data.append(lon)
    data.append(options)
    if let last = lastContent {
      data.append(last.type)
      data.append(last.id)
    } else {
      data.append(UInt8(0xff))
    }
  }
}

