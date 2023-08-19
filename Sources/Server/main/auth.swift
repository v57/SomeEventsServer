//
//  server-auth.swift
//  Server
//
//  Created by Дмитрий Козлов on 2/23/17.
//
//

import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp
import SomeBridge

extension API {
  func auth(commands: inout [cmd: ServerFunction]) {
    commands[.newEvent] = newEvent
    commands[.moveEvent] = moveEvent
    commands[.eventTime] = eventTime
    commands[.searchUsers] = searchUsers
    commands[.userMains] = userMains
    commands[.addFriend] = addFriend
    commands[.removeFriend] = removeFriend
    commands[.subscribe] = subscribe
    commands[.unsubscribe] = unsubscribe
    commands[.leaveEvent] = leaveEvent
    commands[.eventPrivacy] = eventPrivacy
    commands[.eventStatus] = eventStatus
    commands[.invite] = invite
    commands[.uninvite] = uninvite
    commands[.addPhoto] = addPhoto
    commands[.addVideo] = addVideo
    commands[.removeContent] = removeContent
    commands[.sub] = sub
    commands[.removeAvatar] = removeAvatar
    
    commands[.communityChat] = communityChat
    commands[.comments] = comments
    commands[.commentsSettings] = commentsSettings
    commands[.privateChat] = privateChat
    commands[.groupChat] = groupChat
    
    commands[.renameEvent] = renameEvent
    commands[.rename] = rename
    commands[.addPushToken] = addPushToken
    commands[.removePushToken] = removePushToken
    commands[.chat] = chat
  }
}

private func removeAvatar(connection: Connection, data: DataReader) throws {
  print(" removing avatar")
  thread.lock {
    connection.user.removeAvatar(notify: true)
  }
}

private func searchUsers(connection: Connection, data: DataReader) throws {
  let name = try data.string()
  thread.lock()
  let ids = users.names.search(name: name)
  thread.unlock()
  connection.response { data in
    ids.first(50).userVersion(to: data)
  }
}

private func userMains(connection: Connection, data: DataReader) throws {
  let ids = try data.intArray()
  print(" getting \(ids.count) user mains")
  
  let data = connection.response(.ok)
  thread.lock()
  let users = ids.safeUsers
  users.userMain(data: data)
  thread.unlock()
  connection.tsend(data)
}

private func addFriend(connection: Connection, data: DataReader) throws {
  let user = try data.user()
  thread.lock()
  connection.user.add(friend: user, notify: true)
  thread.unlock()
  throw ok
}

private func removeFriend(connection: Connection, data: DataReader) throws {
  let user = try data.user()
  thread.lock()
  connection.user.remove(friend: user, notify: true)
  thread.unlock()
  throw ok
}

private func subscribe(connection: Connection, data: DataReader) throws {
  let user = try data.user()
  thread.lock()
  print("\(connection.user.id) subscribed to \(user.id)")
  connection.user.subscribe(to: user, notify: true)
  thread.unlock()
  throw ok
}


private func unsubscribe(connection: Connection, data: DataReader) throws {
  let user = try data.user()
  thread.lock()
  print("\(connection.user.id) unsubscribed from \(user.id)")
  connection.user.unsubscribe(from: user, notify: true)
  thread.unlock()
  throw ok
}
// MARK:- Event commands

private func newEvent(connection: Connection, data: DataReader) throws {
  let name = try data.string()
  let time = try data.time()
  let lat = try data.float()
  let lon = try data.float()
  let privacy: EventPrivacy = try data.next()
  
  thread.lock()
  let now = Time.now
  let event = Event(id: events.count, name: name, owner: connection.user.id)
  event.createdTime = now
  event.startTime = time
  event.endTime = time + .hour * 2
  event.lat = lat
  event.lon = lon
  event.privacy = privacy
  if !(event.lat == 0 && event.lon == 0) {
    event.options[.onMap] = true
  }
  if event.privacy >= .public {
    if connection.user.allowOnlineEvents {
      event.options.insert(.online)
    }
  }
  if time > now {
    event._status = .paused
  }
  
  events.create(event: event, user: connection.user, notify: false)
  thread.unlock()
  let d = connection.response(.ok)
  d.append(event.id)
  connection.tsend(d)
  thread.lock {
    serverEvents.eventCreated(event: event, by: connection.user)
  }
}

private func moveEvent(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let lat = try data.float()
  let lon = try data.float()
  thread.lock {
    guard event.isInvited(connection.user) else { return }
    event.lat = lat
    event.lon = lon
    if event.lat == 0 && event.lon == 0 {
      if event.isOnMap {
        event.options.remove(.onMap)
        map.eventRemovedFromMap(event: event)
      }
    } else {
      if !event.isOnMap {
        event.options.insert(.onMap)
        map.eventAddedToMap(event: event)
      }
    }
    event.nextPreviewVersion()
    serverEvents.eventMoved(event: event)
  }
  throw ok
}


private func eventTime(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let start = try data.time()
  let end = try data.time()
  let now = Time.now
  try event.check(owner: connection.user)
  let legitTime = start < end && start < now && end < now
  guard legitTime else { throw Response.eventWrongTime }
  thread.lock {
    event.startTime = start
    event.endTime = end
    event.nextPreviewVersion()
    serverEvents.eventTimeChanged(event: event)
  }
  _ = event.status
  throw ok
}


private func enableComments(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let enabled = try data.bool()
  thread.lock()
  defer { thread.unlock() }
  try event.check(invited: connection.user)
  event.comments.isEnabled = enabled
  throw ok
}

private func leaveEvent(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  try thread.lock {
    try event.remove(by: users[event.owner], user: connection.user, notify: true)
  }
  throw ok
}

private func eventPrivacy(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let privacy: EventPrivacy = try data.next()
  try thread.lock {
    guard event.privacy != privacy else { throw ok }
    try event.check(owner: connection.user)
    event.set(privacy: privacy, notify: true)
  }
  throw ok
}

private func eventStatus(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let status: EventStatus = try data.next()
  try thread.lock {
    try event.set(status: status, by: connection.user, notify: true)
  }
  throw ok
}

private func invite(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let users = try data.userArray()
  guard !users.isEmpty else { throw ok }
  try thread.lock {
    for user in users {
      try event.invite(by: connection.user, user: user, notify: true)
    }
  }
  throw ok
}

private func uninvite(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let users = try data.userArray()
  guard !users.isEmpty else { throw ok }
  try thread.lock {
    for user in users {
      try event.remove(by: connection.user, user: user, notify: true)
    }
  }
  throw ok
}

private func commentsSettings(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let option: CommentsOptions = try data.next()
//  let options: CommentsOptions.Set = try data.next()
  try thread.lock {
    let chat = event.comments
    try chat.check(editOptions: connection.user)
    chat.set(option: option, notify: true)
  }
  throw ok
}

private func renameEvent(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let name = try data.string()
  try thread.lock {
    try event.rename(connection.user, name: name, notify: true)
  }
  throw ok
}

private func addPhoto(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let photoData: PhotoData = try data.next()
  var content: Content!
  try thread.lock {
    try event.check(invited: connection.user)
    content = event.newPhoto(author: connection.user.id, photoData: photoData, notify: true, from: connection)
  }
  let data = connection.response(.ok)
  data.append(content.id)
  connection.tsend(data)
}

private func addVideo(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  var content: Content!
  try thread.lock {
    try event.check(invited: connection.user)
    content = event.newVideo(author: connection.user.id, notify: true, from: connection)
  }
  let data = connection.response(.ok)
  data.append(content.id)
  connection.tsend(data)
}
private func removeContent(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let id = try data.int()
  try thread.lock {
    try event.remove(content: id, by: connection.user, notify: true)
  }
  throw ok
}

private func sub(connection: Connection, data: DataReader) throws {
  print("subscribing")
  let count = try data.uint8()
  var subs = Set<Subscription>()
  for _ in 0..<count {
    let subscription = try data.subscription()
    subs.insert(subscription)
  }
  
  thread.lock()
  let removed = connection.subscriptions - subs
  let added = subs - connection.subscriptions
  
  connection.subscriptions = subs
  
  print("disabling by unsubbing (\(removed.count))")
  removed.forEach { $0.disable(connection: connection) }
  added.forEach { $0.enable(connection: connection) }
  
  
  let data = connection.response()
  data.append(added.count)
  for sub in added {
    sub.subscribe(connection: connection, data: data)
  }
  thread.unlock()
  
  connection.tsend(data)
  print("subscribed")
  if subs.count > 0 {
    print("subs:")
    for sub in subs {
      print(sub)
    }
  }
  if added.count > 0 {
    print("added:")
    for sub in added {
      print(sub)
    }
  }
  if removed.count > 0 {
    print("removed:")
    for sub in removed {
      print(sub)
    }
  }
}

// MARK:- requests
extension Chat {
  func send(connection: Connection, data: DataReader) throws {
    let message = try data.message(from: connection.user.id, chat: self)
    try thread.lock {
      guard canSend(user: connection.user, message: message)
        else { throw Response.chatPermissions }
      send(message: message)
    }
  }
  func edit(connection: Connection, data: DataReader) throws {
    let message = try data.message(from: connection.user.id, chat: self)
    try thread.lock {
      guard canEdit(user: connection.user, message: message)
        else { throw Response.chatPermissions }
      let index: Int = try data.next()
      let body: String = try data.next()
      edit(message: index, body: body)
    }
  }
  func delete(connection: Connection, data: DataReader) throws {
    let index = try data.int()
    try thread.lock {
      guard let message = messages.safe(index) else { throw Response.messageNotFound }
      guard canDelete(user: connection.user, message: message)
        else { throw Response.chatPermissions }
      delete(at: index)
    }
  }
  func clear(connection: Connection, data: DataReader) throws {
    try thread.lock {
      guard canClear(user: connection.user)
        else { throw Response.chatPermissions }
      clear()
    }
  }
}

private func chat(connection: Connection, data: DataReader) throws {
  let command: ChatCommands = try data.next()
  let chat = try data.chat()
  switch command {
  case .send:
    try chat.send(connection: connection, data: data)
  case .edit:
    try chat.edit(connection: connection, data: data)
  case .delete:
    try chat.delete(connection: connection, data: data)
  case .clear:
    try chat.clear(connection: connection, data: data)
  }
  throw ok
}

private func communityChat(connection: Connection, data: DataReader) throws {
  let command: ChatCommands = try data.next()
  let chat = chats.community
  switch command {
  case .send:
    try chat.send(connection: connection, data: data)
  case .edit:
    try chat.edit(connection: connection, data: data)
  case .delete:
    try chat.delete(connection: connection, data: data)
  case .clear:
    try chat.clear(connection: connection, data: data)
  }
  throw ok
}

private func comments(connection: Connection, data: DataReader) throws {
  let command: ChatCommands = try data.next()
  let event = try data.event()
  let chat = event.comments
  switch command {
  case .send:
    try chat.send(connection: connection, data: data)
  case .edit:
    try chat.edit(connection: connection, data: data)
  case .delete:
    try chat.delete(connection: connection, data: data)
  case .clear:
    try chat.clear(connection: connection, data: data)
  }
  throw ok
}

private func privateChat(connection: Connection, data: DataReader) throws {
  let command: ChatCommands = try data.next()
  let user = try data.user()
  thread.lock()
  let chat = connection.user.privateChat(for: user)
  thread.unlock()
  switch command {
  case .send:
    try chat.send(connection: connection, data: data)
  case .edit:
    try chat.edit(connection: connection, data: data)
  case .delete:
    try chat.delete(connection: connection, data: data)
  case .clear:
    try chat.clear(connection: connection, data: data)
  }
  throw ok
}

private func groupChat(connection: Connection, data: DataReader) throws {
  let command: ChatCommands = try data.next()
  let id = try data.int()
  thread.lock()
  guard let chat = connection.user.groupChats[id] else {
    thread.unlock()
    throw Response.chatNotFound }
  thread.unlock()
  switch command {
  case .send:
    try chat.send(connection: connection, data: data)
  case .edit:
    try chat.edit(connection: connection, data: data)
  case .delete:
    try chat.delete(connection: connection, data: data)
  case .clear:
    try chat.clear(connection: connection, data: data)
  }
  throw ok
}

//protocol ServerRequest {
//  init(data: DataReader) throws
//  func send(to connection: Connection) throws
//  func received(from connection: Connection)
//}
//
//class Requests {
//
//  class Login: ServerRequest {
//    let id: Int
//    let secret: UInt64
//    required init(data: DataReader) throws {
//      id = try data.int()
//      secret = try data.uint64()
//    }
//
//    func send(to connection: Connection) throws {
//      let sender = connection.sender
//      sender.append(id)
//      sender.append(secret)
//      try connection.send(sender)
//    }
//
//    func received(from connection: Connection) {
//
//    }
//  }
//}


private func rename(connection: Connection, data: DataReader) throws {
  let name = try data.string()
  thread.lock()
  connection.user.rename(name: name, notify: true)
  thread.unlock()
  throw ok
}

private func addPushToken(connection: Connection, data: DataReader) throws {
  let token = try data.string()
  thread.lock()
  pushManager.add(token: token, to: connection.user)
  thread.unlock()
}

private func removePushToken(connection: Connection, data: DataReader) throws {
  let token = try data.string()
  thread.lock()
  pushManager.remove(token: token, from: connection.user)
  thread.unlock()
}



