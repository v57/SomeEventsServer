//
//  private-chat.swift
//  Server
//
//  Created by Дмитрий Козлов on 6/12/17.
//
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class PrivateChat: Chat {
  var user1: ID
  var user2: ID
  func opponent(with other: ID) -> ID {
    if other == user1 {
      return other
    } else {
      return user2
    }
  }
  init(with user1: ID, and user2: ID) {
    self.user1 = user1
    self.user2 = user2
    super.init()
  }
  required init(data: DataReader) throws {
    user1 = try data.int()
    user2 = try data.int()
    try super.init(data: data)
  }
  override func canSend(user: User, message: Message) -> Bool {
    return true
  }
  override func prefix(send data: DataWriter) {
    data.append(subcmd.pm)
  }
  override func prefix(delete data: DataWriter) {
    data.append(subcmd.pmDeleted)
  }
  override func prefix(edit data: DataWriter) {
    data.append(subcmd.pmEdited)
  }
  override func prefix(clear data: DataWriter) {
    data.append(subcmd.pmCleared)
  }
  override func save(data: DataWriter) {
    data.append(user1)
    data.append(user2)
    super.save(data: data)
  }
}
