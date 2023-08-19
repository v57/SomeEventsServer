//
//  users.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 12/8/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class Users: ServerManager, CustomPath {
  let fileName = "users.db"
  static let shared = Users()
  var array: [User] {
    return users
  }
  var users = [User]()
  var count: Int {
    return users.count
  }
  var capacity: Int {
    return users.capacity
  }
  
  var names = Names()
  
  @discardableResult
  func add(user: User) -> Int {
    user.id = count
    users.append(user)
    names.insert(id: user.id, to: user.name)
    return user.id
  }
  
  subscript(id: Int) -> User! {
    guard id >= 0 && id < users.count else { return nil }
    return users[id]
  }
  
  func create(name: String) -> User {
    let user = User(name: name)
    add(user: user)
    return user
  }
  
  func login(id: Int, password: UInt64) throws -> User {
    thread.lock()
    defer { thread.unlock() }
    guard let user = self[id], user.password == password
      else { throw Response.wrongPassword }
    return user
  }
  
//  func rename(user: User, name: String) {
//    user.name = name
//  }
  
  
  
  
  
  
  
  
  
  
  
  
  // MARK:- прочее
  func printAll() {
    print("------------")
    print("Users")
    print(" count: \(count)/\(capacity)")
    var withPhoto = 0
    for user in users {
      if user.avatarVersion > 0 {
        withPhoto += 1
      }
    }
    print(" with photo: \(withPhoto)")
  }
  
  override func start() {
    let console = Console(name: "users")
    console.add(advanced: "create") { command in
      let name = try command.string()
      let user = self.create(name: name)
      if user.avatarURL.exists {
        user.mainVersion.increment()
        user.avatarVersion = 1
      }
      print("created user")
      print("name: \(name)")
      print("id: \(user.id)")
      print("password: \(user.password)")
    }.description = "<login: String>"
    console.add(function: "update avatars") {
      var added = 0
      var removed = 0
      for user in self.users {
        if user.avatarVersion > 0 {
          if !user.avatarURL.exists {
            removed += 1
            user.mainVersion.increment()
            user.avatarVersion = 0
          }
        } else {
          if user.avatarURL.exists {
            added += 1
            user.mainVersion.increment()
            user.avatarVersion = 1
          }
        }
      }
      print("added: \(added), removed: \(removed)")
    }
    console.add(advanced: "print") { command in
      if command.isEmpty {
        self.info(max: nil)
      } else {
        let count = try command.int()
        self.info(max: count)
      }
    }
    terminal.add(command: console, override: .strong)
  }
  private func info(max: Int?) {
    if let max = max {
      for id in 0..<max {
        guard let user = users.safe(id) else { break }
        print("\(id): \(user.name) (avatar: \(user.avatarVersion > 0))")
      }
      print("")
    }
    print("users: \(count)/\(capacity)")
  }
  func load(data: DataReader) throws {
    // users
    let count = try data.int()
    users.reserveCapacity(count)
    reserve()
    for _ in 0..<count {
      let user = User()
      try user.load(data: data)
      append(user: user)
    }
    print("loaded \(count) users")
  }
  func save(data: DataWriter) throws {
    data.append(count)
    for user in self.users {
      user.save(data: data)
    }
  }
  
  private var usersPack = 1000
  func append(user: User) {
    if users.capacity - 10 < users.count {
      reserve()
    }
    users.append(user)
    names.insert(id: user.id, to: user.name)
  }
  func reserve() {
    print("reserving user capacity to \(users.capacity + usersPack)")
    users.reserveCapacity(users.capacity + usersPack)
  }
}

extension Users: TerminalCommands {
  func addCommands() {
    terminal.add(advanced: "search disable") { command in
      let name = try command.text()
      self.names.set(nameException: name, removeCurrent: false)
    }
    terminal.add(advanced: "search remove") { command in
      let name = try command.text()
      self.names.remove(name: name)
    }
  }
}

extension Users {
  struct Names {
    var data = [String: Set<Int>]()
    var exceptions = Set<String>()
    func search(name: String) -> [Int] {
      let name = name.lowercased()
      guard let names = data[name] else { return [] }
      return Array(names)
    }
    mutating func insert(id: Int, to name: String) {
      let name = name.lowercased()
      guard !exceptions.contains(name) else { return }
      if data[name] != nil {
        data[name]!.insert(id)
      } else {
        data[name] = Set([id])
      }
    }
    mutating func remove(_ id: Int, from name: String) {
      let name = name.lowercased()
      data[name]?.remove(id)
    }
    mutating func remove(name: String) {
      let name = name.lowercased()
      data[name] = nil
    }
    mutating func move(user: User, to name: String) {
      remove(user.id, from: user.name)
      insert(id: user.id, to: name)
    }
    mutating func removeFromSearch(user: User) {
      remove(user.id, from: user.name)
    }
    mutating func set(nameException name: String, removeCurrent: Bool) {
      let name = name.lowercased()
      exceptions.insert(name)
      if removeCurrent {
        data[name] = nil
      }
    }
  }
}
