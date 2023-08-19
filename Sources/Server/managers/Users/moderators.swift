//
//  moderators.swift
//  ServerPackageDescription
//
//  Created by Дмитрий Козлов on 12/9/17.
//

import Foundation
import SomeFunctions
import SomeData

class Moderators: ServerManager, CustomPath {
  let fileName = "moderators.db"
  var moderators = Set<Int>()
  var connections: Set<Connection> {
    var set = Set<Connection>()
    moderators.forEach {
      guard let user = $0.user else { return }
      set += user.currentConnections
    }
    return set
  }
  func save(data: DataWriter) throws {
    data.append(moderators)
  }
  func load(data: DataReader) throws {
    try moderators = data.next()
  }
  func insert(_ user: User) {
    user.isModerator = true
    moderators.insert(user.id)
  }
  func remove(_ user: User) {
    user.isModerator = false
    moderators.remove(user.id)
  }
}

extension Moderators: TerminalCommands {
  func addCommands() {
    terminal.add(function: "moderators") {
      let moderators = self.moderators.map { $0 }
      printUsers(moderators)
    }
    let console = User.console
    console.add(function: "moderator") {
      let user = try selectedUser()
      print(user.isModerator)
    }
    console.add(function: "+moderator") {
      let user = try selectedUser()
      self.insert(user)
    }
    console.add(function: "-moderator") {
      let user = try selectedUser()
      self.remove(user)
    }
  }
}


