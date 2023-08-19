//
//  chat.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 11/24/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp
import SomeBridge

enum MainError: Error {
  case notFound
}
var notFound: Error = MainError.notFound

enum ChatType: UInt8 {
  case comments, community, news
  var `class`: Chat.Type {
    switch self {
    case .comments:
      return Comments.self
    case .community:
      return CommunityChat.self
    case .news:
      return NewsChat.self
    }
  }
}
struct ChatLink: DataRepresentable {
  var chat: Chat
  init(data: DataReader) throws {
    let type: ChatType = try data.next()
    if let chat = type.class.read(link: data) {
      self.chat = chat
    } else {
      throw notFound
    }
  }
  func save(data: DataWriter) {
    data.append(chat.type)
    chat.write(link: data)
  }
}

class Chat: DataRepresentable, Versionable {
  static var version = 1
  var messages = [Message]()
  var edited = [Int]()
  var subscribers = Set<Connection>()
  var users = Set<ID>()
  var rawOptions: UInt8? {
    return nil
  }
  
  var url: FileURL {
    overrideRequired()
  }
  var tempURL: FileURL {
    overrideRequired()
  }
  var type: ChatType {
    overrideRequired()
  }
  func write(link: DataWriter) {
    link.append(type)
  }
  class func read(link: DataReader) -> Chat? {
    return nil
  }
  
  init() {}
  required init(data: DataReader) throws {
    users = try data.next()
    if Chat.version == 0 {
      _ = try data.uint16()
    }
    messages = try data.messages(chat: self)
    edited = try data.next()
  }
  subscript(index: Int) -> Message? {
    return messages.safe(index)
  }
  func save(data: DataWriter) {
    data.append(users)
    data.append(messages: messages)
    data.append(edited)
  }
  
  func prefix(main data: DataWriter) { // deprecated
    
  }
  func prefix(send data: DataWriter) { // deprecated
    
  }
  func prefix(edit data: DataWriter) { // deprecated
    
  }
  func prefix(delete data: DataWriter) { // deprecated
    
  }
  func prefix(clear data: DataWriter) { // deprecated
    
  }
  func prefix(uploaded data: DataWriter) { // deprecated
    
  }
  
  func canSend(user: User, message: Message) -> Bool {
    return false
  }
  func canEdit(user: User, message: Message) -> Bool {
    return false
  }
  func canDelete(user: User, message: Message) -> Bool {
    return message.from == user.id || user.isAdmin
  }
  func canClear(user: User) -> Bool {
    return false
  }
  func canDownload(user: User) -> Bool {
    return true
  }
  func canUpload(user: User) -> Bool {
    return true
  }
  func canRead(user: User) -> Bool {
    return true
  }
  
  var nextMessageIndex: Int {
    return messages.count
  }
  
  func send(message: Message) {
    message.index = nextMessageIndex
    messages.append(message)
    
    
    subscribers.splitByVersion { version, subscribers in
      if version > 2 {
        let data = spammer()
        data.append(subcmd.chat)
        data.append(ChatNotifications.received)
        write(link: data)
        data.append(messages.count-1)
        message.write(to: data, writeUser: true, clientVersion: version)
        spam(data: data, to: subscribers)
      } else {
        let data = spammer()
        prefix(send: data)
        prefix(main: data)
        data.append(messages.count-1)
        message.write(to: data, writeUser: true, clientVersion: version)
        spam(data: data, to: subscribers)
      }
    }
  }
  func send(text: String, from: Int) {
    let message = Message(from: from, time: .now, body: text, chat: self)
    send(message: message)
  }
  func edit(message index: Int, body: String) {
    guard let message = messages.safe(index) else { return }
    message.body = MessageBody(text: body)
    edited.append(index)
    
    subscribers.splitByVersion { version, subscribers in
      if version > 2 {
        let data = spammer()
        data.append(subcmd.chat)
        data.append(ChatNotifications.edited)
        write(link: data)
        data.append(index)
        spam(data: data, to: subscribers)
      } else {
        let data = spammer()
        prefix(edit: data)
        prefix(main: data)
        data.append(index)
        spam(data: data, to: subscribers)
      }
    }
  }
  func delete(at index: Int) {
    let message = messages[index]
    message.delete()
    edited.append(index)
    
    subscribers.splitByVersion { version, subscribers in
      if version > 2 {
        let data = spammer()
        data.append(subcmd.chat)
        data.append(ChatNotifications.deleted)
        write(link: data)
        data.append(index)
        spam(data: data, to: subscribers)
      } else {
        let data = spammer()
        prefix(delete: data)
        prefix(main: data)
        data.append(index)
        spam(data: data, to: subscribers)
      }
    }
    
    
  }
  func clear() {
    messages.removeAll()
    subscribers.splitByVersion { version, subscribers in
      if version > 2 {
        let data = spammer()
        data.append(subcmd.chat)
        data.append(ChatNotifications.cleared)
        write(link: data)
        spam(data: data, to: subscribers)
      } else {
        let data = spammer()
        prefix(clear: data)
        prefix(main: data)
        spam(data: data, to: subscribers)
      }
    }
  }
  func uploaded(messageIndex: Int, bodyIndex: Int) {
    subscribers.splitByVersion { version, connections in
      if version > 2 {
        let data = spammer()
        data.append(subcmd.chat)
        data.append(ChatNotifications.uploaded)
        write(link: data)
        data.append(messageIndex)
        data.append(bodyIndex)
        spam(data: data, to: subscribers)
      }
    }
  }
}

//extension MessageType {
//  var classType: Message.Type {
//    switch self {
//    case .text: return TextMessage.self
////    case .photo: return PhotoMessage.self
////    case .video: return VideoMessage.self
////    case .location: return LocationMessage.self
////    case .youtube: return YouTubeMessage.self
//    }
//  }
//}

class Message: CustomStringConvertible, Versionable {
  static var version = 4 // не создавай конфликтов с реквестами плс или ты пидор
  static var localIds = Counter<Int32>()
  var from: ID
  var time: Time
  var localId: Int32
  var body: MessageBody
  var type: MessageType { return .text }
  let chat: Chat
  var index: Int = -1
  
  var isProtected: Bool {
    get { return false }
    set { }
  }
  
  init(from: ID, time: Time, body: String, chat: Chat) {
    self.from = from
    self.localId = Message.localIds.next()
    self.time = time
    self.body = MessageBody(text: body)
    self.chat = chat
  }
  
  init(data: DataReader, from: ID?, chat: Chat) throws {
    if Message.version > 3 {
      self.from = try from ?? data.int()
      time = try data.next()
      localId = try data.next()
      body = try data.next()
    } else if Message.version > 1 {
      self.from = try from ?? data.int()
      time = try data.next()
      localId = try data.next()
      let text = try data.string()
      body = MessageBody(text: text)
    } else if Message.version > 0 {
      self.from = try from ?? data.int()
      time = try data.next()
      localId = Message.localIds.next()
      let text = try data.string()
      body = MessageBody(text: text)
    } else {
      let _: MessageType = try data.next()
      let text = try data.string()
      body = MessageBody(text: text)
      self.from = try from ?? data.int()
      time = try data.time()
      localId = Message.localIds.next()
    }
    self.chat = chat
  }
  init(data: DataReader, from: ID?, chat: Chat, clientVersion: Int) throws {
    self.from = try from ?? data.int()
    time = try data.next()
    localId = try data.next()
    if clientVersion > 2 {
      body = try data.next()
    } else {
      let text = try data.string()
      body = MessageBody(text: text)
    }
    self.chat = chat
  }
  func write(to data: DataWriter, writeUser: Bool, clientVersion: Int) {
    if writeUser {
      data.append(from)
    }
    data.append(time)
    data.append(localId)
    
    if clientVersion > 2 {
      data.append(body)
    } else {
      if body.isDeleted {
        data.append("")
      } else {
        data.append(body.string)
      }
    }
  }
  func write(to data: DataWriter, writeUser: Bool) {
    if writeUser {
      data.append(from)
    }
    data.append(time)
    data.append(localId)
    data.append(body)
  }
  
  func delete() {
    body.delete(message: self)
  }
  
  static func == (l:Message,r:Message) -> Bool {
    return l === r
  }
  
  
  var description: String {
    return "\(from.userName): \(body.string)"
  }
}


extension DataReader {
  func message(from: ID?, chat: Chat, clientVersion: Int) throws -> Message {
    return try Message(data: self, from: from, chat: chat, clientVersion: clientVersion)
  }
  func messages(chat: Chat, clientVersion: Int) throws -> [Message] {
    let count = try int()
    var array = [Message]()
    array.reserveCapacity(count)
    for i in 0..<count {
      let message = try self.message(from: nil, chat: chat, clientVersion: clientVersion)
      message.index = i
      array.append(message)
    }
    return array
  }
  func message(from: ID?, chat: Chat) throws -> Message {
    return try Message(data: self, from: from, chat: chat)
  }
  func messages(chat: Chat) throws -> [Message] {
    let count = try int()
    var array = [Message]()
    array.reserveCapacity(count)
    for i in 0..<count {
      let message = try self.message(from: nil, chat: chat)
      message.index = i
      array.append(message)
    }
    return array
  }
}

extension DataWriter {
  func append<T>(messages: T, writeUser: Bool, clientVersion: Int)
    where T: Sequence, T.Element == Message {
      append(messages.underestimatedCount)
      for message in messages {
        message.write(to: self, writeUser: writeUser, clientVersion: clientVersion)
      }
  }
  func append<T>(messages: T)
    where T: Sequence, T.Element == Message {
    append(messages.underestimatedCount)
    for message in messages {
      message.write(to: self, writeUser: true)
    }
  }
}




