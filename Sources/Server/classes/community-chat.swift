//
//  community-chat.swift
//  Server
//
//  Created by Дмитрий Козлов on 6/7/17.
//
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class CommunityChat: Chat {
  override init() {
    super.init()
  }
  override var url: FileURL {
    return "content/communityChat/".contentURL
  }
  override var tempURL: FileURL {
    return "temp/communityChat/".contentURL
  }
  override var type: ChatType {
    return .community
  }
  override class func read(link: DataReader) -> Chat? {
    return chats.community
  }
  override func canSend(user: User, message: Message) -> Bool {
    return true
  }
  override func canUpload(user: User) -> Bool {
    return true
  }
  
  required init(data: DataReader) throws {
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    super.save(data: data)
  }
}

class NewsChat: Chat {
  override init() {
    super.init()
  }
  override var url: FileURL {
    return "content/news/".contentURL
  }
  override var tempURL: FileURL {
    return "temp/news/".contentURL
  }
  override var type: ChatType {
    return .news
  }
  override class func read(link: DataReader) -> Chat? {
    return chats.news
  }
  override func canSend(user: User, message: Message) -> Bool {
    return true
  }
  override func canUpload(user: User) -> Bool {
    return true
  }
  
  required init(data: DataReader) throws {
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    super.save(data: data)
  }
}
