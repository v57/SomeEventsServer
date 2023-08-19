//
//  Subscriptions.swift
//  Server
//
//  Created by Дмитрий Козлов on 1/11/18.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

extension Subtype {
  var `class`: Subscription.Type {
    switch self {
    case .map: return Subscription.Map.self
    case .event: return Subscription.Event.self
    case .profile: return Subscription.Profile.self
    case .reports: return Subscription.Reports.self
    case .comments: return Subscription.Comments.self
    case .groupChat: return Subscription.GroupChat.self
    case .privateChat: return Subscription.PrivateChat.self
    case .communityChat: return Subscription.CommunityChat.self
    case .news: return Subscription.News.self
    }
  }
}

extension DataReader {
  func subscription() throws -> Subscription {
    let type: Subtype = try self.enum()
    return try type.class.init(data: self)
  }
}

class Subscription: DataRepresentable, Hashable, CustomStringConvertible, Versionable {
  static var version = 0
  var type: Subtype { overrideRequired() }
  var description: String { overrideRequired() }
  var string: String { return String(type.rawValue) }
  func enable(connection: Connection) { overrideRequired() }
  func disable(connection: Connection) { overrideRequired() }
  func subscribe(connection: Connection, data: DataWriter) { overrideRequired() }
  
  required init(data: DataReader) throws {
    
  }
  func save(data: DataWriter) {
    data.append(type)
  }
  static func == (l: Subscription, r: Subscription) -> Bool {
    return l.description == r.description
  }
  var hashValue: Int {
    return description.hashValue
  }
  
  
  // MARK:- Profile
  class Profile: Subscription {
    override var type: Subtype { return .profile }
    override var description: String {
      return "profile \(id.userName)"
    }
    override var string: String {
      return "\(type.rawValue),\(id)"
    }
    
    let id: ID
    required init(data: DataReader) throws {
      id = try data.next()
      try super.init(data: data)
    }
    override func save(data: DataWriter) {
      super.save(data: data)
      data.append(id)
    }
    override func enable(connection: Connection) {
      users[id].profileConnections.insert(connection)
    }
    override func disable(connection: Connection) {
      guard let user = users[id] else { return }
      user.profileConnections.remove(connection)
    }
    override func subscribe(connection: Connection, data: DataWriter) {
      let me = connection.user!
      save(data: data)
      user(id, data) { user in
        user.write(main: data)
        data.append(user.subscribers.count)
        data.append(user.subscriptions.count)
        data.append(user.subscriptions.contains(me.id))
        user.events
          .events
          .filter { !$0.isPrivate(for: me) }
          .eventMain(data: data)
      }
    }
  }
  
  
  
  // MARK:- Map
  class Map: Subscription {
    override var type: Subtype {
      return .map
    }
    override var description: String {
      return "map"
    }
    
    override func enable(connection: Connection) {
      map.subs.insert(connection)
    }
    override func disable(connection: Connection) {
      map.subs.remove(connection)
    }
    override func subscribe(connection: Connection, data: DataWriter) {
      save(data: data)
      data.ok()
      map.displayed.eventMain(data: data)
    }
  }
  
  
  
  // MARK:- Event
  class Event: Subscription {
    override var type: Subtype {
      return .event
    }
    override var description: String {
      return "event \(id.eventName)"
    }
    override var string: String {
      return "\(type.rawValue),\(id)"
    }
    
    let id: ID
    required init(data: DataReader) throws {
      id = try data.next()
      try super.init(data: data)
    }
    override func save(data: DataWriter) {
      super.save(data: data)
      data.append(id)
    }
    override func enable(connection: Connection) {
      guard let event = events[id] else { return }
      event.visit(user: connection.user, notify: true)
      event.subs.insert(connection)
    }
    override func disable(connection: Connection) {
      guard let event = events[id] else { return }
      event.unvisit(user: connection.user, notify: true)
      print("unvisiting by \(self)")
      print("current visitors: \(event.current)")
      event.subs.remove(connection)
    }
    override func subscribe(connection: Connection, data: DataWriter) {
      save(data: data)
      event(id, data) { event in
        event.eventMain(data: data)
        data.append(event.owner)
        
        data.append(contents: event.content.values)
        
        event.invited.userMain(data: data)
        data.append(event.views)
        data.append(event.current)
        data.append(event.comments.messages.count)
        data.append(event.options)
        data.append(event.privacy)
        data.append(event.status)
      }
    }
  }
  
  
  
  // MARK:- Reports
  class Reports: Subscription {
    override var type: Subtype {
      return .reports
    }
    override var description: String {
      return "reports"
    }
    
    override func enable(connection: Connection) {
      reports.subscribers.insert(connection)
    }
    override func disable(connection: Connection) {
      reports.subscribers.remove(connection)
    }
    override func subscribe(connection: Connection, data: DataWriter) {
      save(data: data)
      /*
       uint8 .ok (always ok)
       int unchecked reports count
       int unique unchecked reports count
       int reports count
       *^*
       uint8 report type
       int id
       int from count
       int accepted count
       int declined count
       * report body
       */
      data.ok()
      let array = reports.reports(count: 50)
      data.append(reports.count)
      data.append(reports.uncheckedCount)
      data.append(array.count)
      for report in array {
        report.preview(body: data)
      }
    }
  }
  
  // MARK:- Chat
  class ChatSubscription: Subscription {
    let lastEdit: Int
    let firstMessage: Int
    let lastMessage: Int
    
    func chat(for connection: Connection) -> Chat? {
      overrideRequired()
    }
    
    required init(data: DataReader) throws {
      lastEdit = try data.next()
      firstMessage = try data.next()
      lastMessage = try data.next()
      try super.init(data: data)
    }
    override func enable(connection: Connection) {
      chat(for: connection)?.subscribers.insert(connection)
    }
    override func disable(connection: Connection) {
      chat(for: connection)?.subscribers.remove(connection)
    }
    override func subscribe(connection: Connection, data: DataWriter) {
      save(data: data)
      chat(data: data, connection: connection) { chat in
        if let options = chat.rawOptions {
          data.append(options)
        }
        chat.users.userMain(data: data)
        let startIndex: Int
        let messages: ArraySlice<Message>
        if firstMessage == 0 {
          messages = chat.messages.last(100)
          startIndex = chat.messages.count - messages.count
        } else {
          messages = chat.messages.from(lastMessage, max: 100)
          startIndex = lastMessage
        }
        data.append(chat.messages.count)
        data.append(startIndex)
        data.append(messages: messages, writeUser: true, clientVersion: connection.version)
        data.append(chat.edited.count)
        
        var indexes = Set<Int>()
        for index in chat.edited.from(lastEdit) {
          guard index >= firstMessage && index < lastMessage else { continue }
          indexes.insert(index)
        }
        data.append(indexes.count)
        for index in chat.edited where index < lastMessage {
          let message = chat.messages[index]
          data.append(index)
          message.write(to: data, writeUser: true, clientVersion: connection.version)
        }
      }
    }
    func chat(data: DataWriter, connection: Connection, completion: (Chat)->()) {
      if let chat = self.chat(for: connection) {
        data.ok()
        completion(chat)
      } else {
        data.append(Response.subscriptionNotFound)
      }
    }
  }
  
  // MARK:- IDChatSubscription
  class IDChatSubscription: ChatSubscription {
    let id: ID
    required init(data: DataReader) throws {
      id = try data.next()
      try super.init(data: data)
    }
    override func save(data: DataWriter) {
      super.save(data: data)
      data.append(id)
    }
  }
  
  // MARK:- Comments
  class Comments: IDChatSubscription {
    override var type: Subtype { return .comments }
    override var description: String { return "event comments \(id.eventName)" }
    override var string: String { return "\(type.rawValue),\(id)" }
    override func chat(for connection: Connection) -> Chat? {
      return id.event?.comments
    }
  }
  
  // MARK:- GroupChat
  class GroupChat: IDChatSubscription {
    override var type: Subtype { return .groupChat }
    override var description: String { return "group chat \(id)" }
    override var string: String { return "\(type.rawValue),\(id)" }
    override func chat(for connection: Connection) -> Chat? {
      return connection.user.groupChats[id]
    }
  }
  
  // MARK:- PrivateChat
  class PrivateChat: IDChatSubscription {
    override var type: Subtype { return .privateChat }
    override var description: String { return "private chat with \(id.userName)" }
    override var string: String { return "\(type.rawValue),\(id)" }
    override func chat(for connection: Connection) -> Chat? {
      guard let user = id.user else { return nil }
      return connection.user.privateChat(for: user)
    }
  }
  
  // MARK:- CommunityChat
  class CommunityChat: ChatSubscription {
    override var type: Subtype { return .communityChat }
    override var description: String { return "community chat" }
    override func chat(for connection: Connection) -> Chat? {
      return chats.community
    }
  }
  class News: ChatSubscription {
    override var type: Subtype { return .news }
    override var description: String { return "news" }
    override func chat(for connection: Connection) -> Chat? {
      return chats.news
    }
  }
}







private extension DataWriter {
  func ok() {
    append(Response.ok)
  }
}
private func event(_ id: ID, _ data: DataWriter, success: (Event)->()) {
  if let event = events[id] {
    data.ok()
    success(event)
  } else {
    data.append(Response.subscriptionNotFound)
  }
}
private func user(_ id: ID, _ data: DataWriter, success: (User)->()) {
  if let user = users[id] {
    data.ok()
    success(user)
  } else {
    data.append(Response.subscriptionNotFound)
  }
}
private func report(_ id: ID, _ data: DataWriter, success: (Report)->()) {
  if let report = reports[id] {
    data.ok()
    success(report)
  } else {
    data.append(Response.subscriptionNotFound)
  }
}
private func groupChat(_ user: User, _ id: ID, _ data: DataWriter, success: (GroupChat)->()) {
  if let chat = user.groupChats[id] {
    data.ok()
    success(chat)
  } else {
    data.append(Response.subscriptionNotFound)
  }
}

