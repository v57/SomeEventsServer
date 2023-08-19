//
//  chats.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 12/8/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp
import SomeBridge

extension ID {
  static var groupChat: ID {
    return chats.counter.next()
  }
}

class Chats: ServerManager, CustomPath, CounterManager {
  let version = 2
  var counter = Counter<ID>()
  let fileName = "chats.db"
  
  var community = CommunityChat()
  var news = NewsChat()
  private var chats = [Int: GroupChat]()
  
  
  subscript(id: Int) -> GroupChat? {
    return chats[id]
  }
  
  @discardableResult
  func create(members: Set<Int>, admins: Set<Int>) -> GroupChat {
    let chat = GroupChat(id: .groupChat, invited: members, admins: admins)
    add(chat: chat)
    
    let data = spammer()
    data.append(subcmd.gcCreated)
    data.append(chat.id)
    
    for id in members {
      let user = users[id]!
      spam(data: data, to: user.currentConnections)
    }
    return chat
  }
  
  
  func remove(chat id: Int) {
    guard id >= 0 && id < chats.count else { return }
    chats[id] = nil
  }
  
  
  @discardableResult
  func add(chat: GroupChat) -> Int {
    chat.id = .groupChat
    chats[chat.id] = chat
    return chat.id
  }
  
  func load(data: DataReader) throws {
    if version > 2 {
      community = try data.next()
      news = try data.next()
    }
//    guard let data = DataReader(path: .chats) else { return }
//    chatsCount = try data.int()
//    for _ in 0..<chatsCount {
//      let chat = try PublicChat(data: data)
//      chats[chat.id] = chat
//    }
  }
  func save(data: DataWriter) throws {
    data.append(community)
    data.append(news)
//    let data = DataWriter()
//    data.append(chatsCount)
//    for chat in chats {
//      chat?.save(data: data)
//    }
//    data.write(to: .chats)
  }
}

extension Chats {
  func write(startData data: DataWriter, me: User, id: Int) {
    
  }
  func enable(connection: Connection, id: Int) {
    
  }
  func disable(connection: Connection, id: Int) {
    
  }
}

