//
//  group-chat.swift
//  Server
//
//  Created by Дмитрий Козлов on 6/12/17.
//
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class GroupChat: Chat {
  var id: ID
  var invited: Set<ID>
  var admins: Set<ID>
  init(id: ID, invited: Set<ID>, admins: Set<ID>) {
    self.id = id
    self.invited = invited
    self.admins = admins
    super.init()
  }
  required init(data: DataReader) throws {
    self.id = try data.next()
    self.invited = try data.next()
    self.admins = try data.next()
    try super.init(data: data)
  }
  override func canSend(user: User, message: Message) -> Bool {
    return true
  }
  override func prefix(send data: DataWriter) {
    data.append(subcmd.gc)
  }
  override func prefix(delete data: DataWriter) {
    data.append(subcmd.gcDeleted)
  }
  override func prefix(edit data: DataWriter) {
    data.append(subcmd.gcEdited)
  }
  override func prefix(clear data: DataWriter) {
    data.append(subcmd.gcCleared)
  }
  override func save(data: DataWriter) {
    data.append(id)
    data.append(users)
    data.append(admins)
    super.save(data: data)
  }
}
