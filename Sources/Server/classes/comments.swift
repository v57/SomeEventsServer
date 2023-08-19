//
//  comments.swift
//  Server
//
//  Created by Дмитрий Козлов on 4/10/17.
//
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class Comments: Chat {
  var id = ID()
  var event: Event { return id.event }
  var options = CommentsOptions.Set()
  override var rawOptions: UInt8? {
    return options.rawValue
  }
  
  override var url: FileURL {
    return "content/events/\(id)/comments/".contentURL
  }
  override var tempURL: FileURL {
    return "temp/events/\(id)/comments/".contentURL
  }
  override var type: ChatType {
    return .comments
  }
  override func write(link: DataWriter) {
    super.write(link: link)
    link.append(id)
  }
  override class func read(link: DataReader) -> Comments? {
    return (try? link.id())?.event?.comments
  }
  
  func isOwner(_ user: User) -> Bool {
    return event.owner == user.id || user.isAdmin
  }
  func isInvited(_ user: User) -> Bool {
    return event.invited.contains(user.id) || user.isAdmin
  }
  
  override func canSend(user: User, message: Message) -> Bool {
    guard let event = id.event else { return false }
    guard isEnabled else { return event.invited.contains(user.id) }
    guard !event.isPrivate(for: user) else { return false }
    users.insert(message.from)
    return true
  }
  override func canClear(user: User) -> Bool {
    return event.invited.contains(user.id)
  }
  override func canDelete(user: User, message: Message) -> Bool {
    return super.canDelete(user: user, message: message) || event.isInvited(user)
  }
  override func canEdit(user: User, message: Message) -> Bool {
    return message.from == user.id || user.isAdmin
  }
  override func send(message: Message) {
    super.send(message: message)
    var ids = event.invited
    ids.remove(message.from)
    if event.views < 10000 {
      pushManager.push(to: ids.users, notification: .comment(event, message))
    }
  }
  func check(editOptions user: User) throws {
    guard isInvited(user) else { throw Response.eventPermissions }
  }
//  func canEditOptions(user: User) -> Bool {
//    return isInvited(user)
//  }
  func set(option: CommentsOptions, notify: Bool) {
    guard !options.contains(option) else { return }
    options.insert(option)
    if notify {
      serverEvents.ecEnabled(event: id.event)
    }
  }
  init(id: ID) {
    self.id = id
    super.init()
  }
  required init(data: DataReader) throws {
    id = try data.next()
    options = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(id)
    data.append(options)
    super.save(data: data)
  }
  override func prefix(send data: DataWriter) { // deprecated
    data.append(subcmd.ec)
    data.append(id)
  }
  override func prefix(edit data: DataWriter) { // deprecated
    data.append(subcmd.ecEdited)
//    data.append(id)
  }
  override func prefix(clear data: DataWriter) { // deprecated
    data.append(subcmd.ecCleared)
    data.append(id)
  }
  override func prefix(delete data: DataWriter) { // deprecated
    data.append(subcmd.ecDeleted)
    data.append(id)
  }
  func optionsChanged() {
    
  }
}

extension Comments {
  var isEnabled: Bool {
    get {
      return !options[.disabled]
    } set {
      options[.disabled] = newValue
    }
  }
}
