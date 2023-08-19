//
//  user.swift
//  faggot server
//
//  Created by Дмитрий Козлов on 07/03/16.
//  Copyright © 2016 anus. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

enum FriendStatus {
  case none, request, friend
}

extension FixedWidthInteger {
  mutating func increment() {
    self = self &+ 1
  }
}

class User: DataLoadable, Versionable {
  static var version = 2
  var id = ID()
  
  // main
  var name = String() { didSet { mainVersion.increment() } }
  var publicOptions = PublicUserOptions.default
  var avatarVersion = UserAvatarVersion() { didSet { mainVersion.increment() } }
  var mainVersion = UserMainVersion()
  
  func loadMain(data: DataReader) throws {
    name = try data.next()
    publicOptions = try data.next()
    avatarVersion = try data.next()
    mainVersion = try data.next()
  }
  func saveMain(data: DataWriter) {
    data.append(name)
    data.append(publicOptions)
    data.append(avatarVersion)
    data.append(mainVersion)
  }
  func write(main data: DataWriter) {
    data.append(name)
    data.append(publicOptions)
    data.append(avatarVersion)
    data.append(mainVersion)
  }
  func print(main data: inout [String]) {
    data.append("name: \(name)")
    data.append("publicOptions: \(publicOptions.description(withInit: { PublicUserOptions(rawValue: $0) }))")
    data.append("avatarVersion: \(avatarVersion)")
    data.append("mainVersion: \(mainVersion)")
  }
  
  // public profile
  var publicProfileVersion = UserProfileVersion()
  var events = Set<Int>()
  
  func loadPublicProfile(data: DataReader) throws {
    publicProfileVersion = try data.next()
    events = try data.next()
  }
  func savePublicProfile(data: DataWriter) {
    data.append(publicProfileVersion)
    data.append(events)
  }
  func print(publicProfile data: inout [String]) {
    data.append("publicProfileVersion: \(publicProfileVersion)")
    data.append("events: \(events.count)")
  }
  
  // private profile
  var privateOptions = PrivateUserOptions.default
  var privateProfileVersion = UserPrivateVersion()
  var friends = Set<Int>()
  var subscribers = Set<Int>()
  var subscriptions = Set<Int>()
  var outcoming = Set<Int>()
  var incoming = Set<Int>()
  var favorite = Set<Int>()
  
  var privateChats = [Int: PrivateChat]()
  var groupChats = [Int: GroupChat]()
  
  var reports = Set<Report>()
  var reportsAccepted: UInt16 = 0
  var reportsDeclined: UInt16 = 0
  
  func loadPrivateProfile(data: DataReader) throws {
    privateOptions = try data.next()
    privateProfileVersion = try data.next()
    friends = try data.next()
    subscribers = try data.next()
    
    subscriptions = try data.next()
    outcoming = try data.next()
    incoming = try data.next()
    favorite = try data.next()
    
    let privateChats: [PrivateChat] = try data.next()
    for chat in privateChats {
      self.privateChats[chat.opponent(with: id)] = chat
    }
    let groupChats: [GroupChat] = try data.next()
    for chat in groupChats {
      self.groupChats[chat.id] = chat
    }
    
    reportsAccepted = try data.next()
    reportsDeclined = try data.next()
  }
  func savePrivateProfile(data: DataWriter) {
    data.append(privateOptions)
    data.append(privateProfileVersion)
    data.append(friends)
    data.append(subscribers)
    
    data.append(subscriptions)
    data.append(outcoming)
    data.append(incoming)
    data.append(favorite)
    
    data.append(Array(privateChats.values))
    data.append(Array(groupChats.values))
    
    data.append(reportsAccepted)
    data.append(reportsDeclined)
  }
  
  func print(privateProfile data: inout [String]) {
    data.append("privateOptions: \(privateOptions.description(withInit: { PrivateUserOptions(rawValue: $0) }))")
    data.append("privateProfileVersion: \(privateProfileVersion)")
    data.append("friends: \(friends)")
    data.append("subscribers: \(subscribers)")
    data.append("subscriptions: \(subscriptions)")
    data.append("outcoming: \(outcoming)")
    data.append("incoming: \(incoming)")
    data.append("favorite: \(favorite)")
    
    data.append("privateChats: \(privateChats.map { $0.key })")
    data.append("groupChats: \(groupChats.map { $0.key })")
    
    data.append("reports: \(reports.map { $0.id })")
    data.append("reportsAccepted: \(reportsAccepted)")
    data.append("reportsDeclined: \(reportsDeclined)")
  }
  
  // server private
  var serverOptions = ServerUserOptions.default
  var password = UInt64()
  var tokens = Set<String>()
  var views = Set<Int>()
  
  func loadServerPrivate(data: DataReader) throws {
    serverOptions = try data.next()
    password = try data.next()
    tokens = try data.next()
    views = try data.next()
  }
  func saveServerPrivate(data: DataWriter) {
    data.append(serverOptions)
    data.append(password)
    data.append(tokens)
    data.append(views)
  }
  func print(serverPrivate data: inout [String]) {
    data.append("serverOptions: \(serverOptions.description(withInit: { ServerUserOptions(rawValue: $0) }))")
    data.append("password: \(password)")
    data.append("tokens: \(tokens)")
    data.append("views: \(views.count)")
  }
  
  // non storable
  var currentConnections = Set<Connection>()
  var currentDownloads = Set<Connection>()
  var currentUploads = Set<Connection>()
  var profileConnections = Set<Connection>()
  
  func load(data: DataReader) throws {
    id = try data.next()
    try loadMain(data: data)
    try loadPublicProfile(data: data)
    try loadPrivateProfile(data: data)
    try loadServerPrivate(data: data)
  }
  
  func save(data: DataWriter) {
    data.append(id)
    saveMain(data: data)
    savePublicProfile(data: data)
    savePrivateProfile(data: data)
    saveServerPrivate(data: data)
  }
  
  func print(nonStorable data: inout [String]) {
    data.append("currentConnections: \(currentConnections.count)")
    data.append("currentDownloads: \(currentDownloads.count)")
    data.append("currentUploads: \(currentUploads.count)")
    data.append("profileConnections: \(profileConnections.count)")
  }
  
  required init() {}
  init(name: String) {
    self.name = name
    self.password = .random()
  }
  
  @discardableResult
  func add(friend user: User, notify: Bool) -> FriendStatus {
    guard !friends.contains(user.id) && !outcoming.contains(user.id) else { return .none }
    if incoming.contains(user.id) {
      incoming.remove(user.id)
      friends.insert(user.id)
      user.outcoming.remove(id)
      user.friends.insert(id)
      
      privateProfileVersion.increment()
      user.privateProfileVersion.increment()
      if notify {
        serverEvents.friendAdded(user: self, friend: user)
        serverEvents.friendAdded(user: user, friend: self)
      }
      return .friend
    } else {
      outcoming.insert(user.id)
      user.incoming.insert(id)
      
      privateProfileVersion.increment()
      user.privateProfileVersion.increment()
      if notify {
        serverEvents.outcomingAdded(user: self, friend: user)
        serverEvents.incomingAdded(user: user, friend: self)
      }
      return .request
    }
  }
  func remove(friend user: User, notify: Bool) {
    if friends.contains(user.id) {
      friends.remove(user.id)
      user.friends.remove(id)
    } else if incoming.contains(user.id) {
      incoming.remove(id)
      user.outcoming.remove(id)
    } else if outcoming.contains(user.id) {
      outcoming.remove(user.id)
      user.incoming.remove(user.id)
    } else {
      return
    }
    privateProfileVersion.increment()
    user.privateProfileVersion.increment()
    if notify {
      serverEvents.friendRemoved(user: self, friend: user)
      serverEvents.friendRemoved(user: user, friend: self)
    }
  }
  func rename(name: String, notify: Bool) {
    guard self.name != name else { return }
    users.names.move(user: self, to: name)
    mainVersion.increment()
    self.name = name
    if notify {
      serverEvents.rename(user: self, name: name)
    }
  }
  
  func updateAvatar(notify: Bool) {
    mainVersion.increment()
    avatarVersion.increment()
    hasAvatar = true
    if notify {
      serverEvents.avatarChanged(user: self)
    }
  }
  
  func removeAvatar(notify: Bool) {
    hasAvatar = false
    if notify {
      serverEvents.avatarRemoved(user: self)
    }
  }
  
  @discardableResult
  func subscribe(to user: User, notify: Bool) -> Bool {
    guard !subscriptions.contains(user.id) else { return false }
    subscriptions.insert(user.id)
    user.subscribed(self)
    privateProfileVersion.increment()
    user.privateProfileVersion.increment()
    if notify {
      serverEvents.subscribed(user: user, subscriber: self)
    }
    return true
  }
  
  @discardableResult
  func unsubscribe(from user: User, notify: Bool) -> Bool {
    guard subscriptions.contains(user.id) else { return false }
    subscriptions.remove(user.id)
    user.unsubscribed(self)
    privateProfileVersion.increment()
    user.privateProfileVersion.increment()
    if notify {
      serverEvents.unsubscribed(user: user, subscriber: self)
    }
    return true
  }
  fileprivate func subscribed(_ user: User) {
    subscribers.insert(user.id)
  }
  fileprivate func unsubscribed(_ user: User) {
    subscribers.remove(user.id)
  }
  func login(_ password: UInt64) -> Bool {
    return self.password == password
  }
  
  
  //////////////////////
  // MARK: Chat
  //////////////////////
  func privateChat(for user: User) -> PrivateChat {
    if let chat = privateChats[user.id] {
      return chat
    } else {
      let chat = PrivateChat(with: self.id, and: user.id)
      privateChats[user.id] = chat
      user.privateChats[user.id] = chat
      return chat
    }
  }
  
  // push
  func push(_ notification: PushNotification) {
    pushManager.push(to: self, notification: notification)
  }
  func push(title: String, text: String?) {
    pushManager.push(to: self, notification: .text(title, text))
  }
}


// MARK:- setters/getters
extension User {
  var isOnline: Bool {
    get {
      return publicOptions.contains(.online)
    } set {
      if newValue {
        publicOptions.insert(.online)
      } else {
        publicOptions.remove(.online)
      }
    }
  }
  var hasAvatar: Bool {
    get {
      return publicOptions.contains(.avatar)
    } set {
      if newValue {
        publicOptions.insert(.avatar)
      } else {
        publicOptions.remove(.avatar)
      }
    }
  }
  var isDeleted: Bool {
    get {
      return publicOptions.contains(.deleted)
    } set {
      if newValue {
        publicOptions.insert(.deleted)
      } else {
        publicOptions.remove(.deleted)
      }
    }
  }
  var isBanned: Bool {
    get {
      return publicOptions.contains(.banned)
    } set {
      if newValue {
        publicOptions.insert(.banned)
      } else {
        publicOptions.remove(.banned)
      }
    }
  }
  

  var allowReports: Bool {
    get {
      return privateOptions[.allowReports]
    } set {
      privateProfileVersion.increment()
      privateOptions[.allowReports] = newValue
    }
  }
  var isModerator: Bool {
    get {
      return privateOptions.contains(.moderator)
    } set {
      privateProfileVersion.increment()
      if newValue {
        privateOptions.insert(.moderator)
      } else {
        privateOptions.remove(.moderator)
      }
    }
  }
  var isAdmin: Bool {
    get {
      return privateOptions.contains(.admin)
    } set {
      privateProfileVersion.increment()
      if newValue {
        privateOptions.insert(.admin)
      } else {
        privateOptions.remove(.admin)
      }
    }
  }
  
  var isProtected: Bool {
    get {
      return serverOptions.contains(.protected)
    } set {
      if newValue {
        serverOptions.insert(.protected)
      } else {
        serverOptions.remove(.protected)
      }
    }
  }
  var allowOnlineEvents: Bool {
    get {
      return !serverOptions.contains(.allowOnlineEvents)
    } set {
      if !newValue {
        serverOptions.insert(.allowOnlineEvents)
      } else {
        serverOptions.remove(.allowOnlineEvents)
      }
    }
  }
  var allowComments: Bool {
    get {
      return serverOptions.contains(.allowComments)
    } set {
      if newValue {
        serverOptions.insert(.allowComments)
      } else {
        serverOptions.remove(.allowComments)
      }
    }
  }
  var reportsSent: Int {
    return reports.count + Int(reportsAccepted) + Int(reportsDeclined)
  }
}

extension ID {
  var user: User? {
    return users[self]
  }
  var userName: String {
    var a = "\(self)"
    if let user = user {
      a += " \(user.name)"
    }
    return a
  }
  func userVersion(data: DataWriter) {
    let user = users[self]!
    user.userVersion(data: data)
  }
  func userMain(data: DataWriter) {
    let user = self.user!
    user.userMain(data: data)
  }
}

extension User {
  func userVersion(data: DataWriter) {
    data.append(id)
    data.append(mainVersion)
  }
  func userMain(data: DataWriter) {
    data.append(id)
    write(main: data)
  }
}

extension Sequence where Iterator.Element == User {
  var ids: [Int] { return map { $0.id } }
  func push(_ notification: PushNotification) {
    pushManager.push(notification: notification, to: tokens)
  }
  func push(title: String, text: String?) {
    pushManager.push(notification: .text(title, text), to: tokens)
  }
  func userVersion(to data: DataWriter) {
    data.append(underestimatedCount)
    forEach { $0.userVersion(data: data) }
  }
  func userMain(data: DataWriter) {
    data.append(underestimatedCount)
    forEach { $0.userMain(data: data) }
  }
  var tokens: Set<String> {
    var tokens = Set<String>()
    for user in self {
      tokens += user.tokens
    }
    return tokens
  }
}


extension Sequence where Iterator.Element == Int {
  var users: [User] { return map { $0.user! } }
  var safeUsers: [User] {
    return compactMap { return $0.user }
  }
  
  /// unchecked
  func userVersion(to data: DataWriter) {
    data.append(underestimatedCount)
    forEach { $0.userVersion(data: data) }
  }
  func userMain(data: DataWriter) {
    data.append(underestimatedCount)
    forEach { $0.userMain(data: data) }
  }
}

extension User: Hashable {
  static func ==(lhs: User, rhs: User) -> Bool {
    return lhs.id == rhs.id
  }
  
  var hashValue: Int { return id.hashValue }
}
