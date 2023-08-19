//
//  admins.swift
//  Server
//
//  Created by Дмитрий Козлов on 12/17/17.
//

import Foundation
import SomeData
import SomeFunctions
import SomeBridge

extension User {
  static var server: User { return users[0]! }
}

class Admins: ServerManager, CustomPath {
  let fileName = "admins.db"
  var admins = Set<ID>()
  var connections: Set<Connection> {
    var set = Set<Connection>()
    admins.forEach {
      guard let user = $0.user else { return }
      set += user.currentConnections
    }
    return set
  }
  func save(data: DataWriter) throws {
    data.append(admins)
  }
  func load(data: DataReader) throws {
    try admins = data.next()
  }
  func insert(_ user: User) {
    user.isAdmin = true
    admins.insert(user.id)
  }
  func remove(_ user: User) {
    user.isAdmin = false
    admins.remove(user.id)
  }
  func received(report: Report) {
    let notification = PushNotification.text("New report", "Received \(report.type) report from \(report.from.first!.user!.name)")
    pushManager.push(to: admins.users, notification: notification)
  }
}

extension Admins: AdminCommands {
  func admin(commands: inout [cmd : ServerFunction]) {
    
  }
}

extension Admins: TerminalCommands {
  func addCommands() {
    terminal.add(function: "server user") {
      if let user = users[0] {
        user.rename(name: "Server", notify: true)
        self.insert(user)
        moderators.insert(user)
      } else {
        let user = users.create(name: "Server")
        self.insert(user)
        moderators.insert(user)
      }
    }
    terminal.add(function: "admins") {
      let admins = self.admins.map { $0 }
      printUsers(admins)
    }
    let console = User.console
    console.add(function: "admin") {
      let user = try selectedUser()
      print(user.isAdmin)
    }
    console.add(function: "admin set") {
      let user = try selectedUser()
      self.insert(user)
    }
    console.add(function: "admin remove") {
      let user = try selectedUser()
      self.remove(user)
    }
  }
}
