//
//  input.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 08/06/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
//-import SomeTcp
import SomeData
import SomeBridge

func addCommands() {
  mainCommands()
  userCommands()
  eventCommands()
  ceo.managers
    .compactMap { $0 as? TerminalCommands }
    .forEach { $0.addCommands() }
}

protocol TerminalCommands {
  func addCommands()
}

private func mainCommands() {
  terminal.add(function: "stop") {
    server.close()
    db.stop()
    terminal.listening = false
    exit(9)
  }
  terminal.add(advanced: "settings willSave") { command in
    if command.data.count > 0 {
      let state = try command.int()
      if state == 1 {
        db.willSave = true
      } else if state == 0 {
        db.willSave = false
      }
    } else {
      print("willSave = \(db.willSave)")
    }
  }.description = "<willSave: Int?> # get/set willSave parameter"
  terminal.add(function: "delete save") {
    let files = "data".dbURL.content
    for file in files {
      file.delete()
      print("\(file.url.lastPathComponent) deleted")
    }
  }
  terminal.add(function: "save") {
    db.save()
  }
  terminal.add(function: "backup") {
    db.backup()
  }
  terminal.add(function: "backup restore") {
    db.restore(1)
  }
  terminal.add(advanced: "connect") { command in
    var ip = try command.string()
    switch ip {
    case "wifi":
      guard let wifi = IP.wifi else {
        print("no wifi")
        return
      }
      ip = wifi
    case "public":
      guard let pub = IP.public else {
        print("no internet")
        return
      }
      ip = pub
    case "localhost":
      ip = localhost
    default: break
    }
    guard let newAddress = IP(string: ip) else {
      print("are you fuckin retarded?")
      throw CmdError.noprint
    }
    address = newAddress
    server.close()
    server = Server(port: address.port)
    try? server.start()
  }.description = "<ip: String> # 127.0.0.1 / 127.0.0.1:1989 / localhost / wifi / public"
  terminal.add(withParameters: "restart") { command, params in
    if params.contains("e") {
      restart()
    } else {
      restartApp()
    }
  }.description = "# -e easy restart"
  terminal.add(advanced: "system message") { command in
    let text = try command.text()
    
    var connections = Set<Connection>()
    users.array.forEach { connections += $0.currentConnections }
    serverEvents.systemMessage(text: text, to: connections)
  }.description = "<message: String> # sends message to all online devices"
  
  terminal.add(advanced: "generate rsa") { command in
    var size = 2048
    var file = "key"
    if !command.isEmpty {
      let first = try command.string()
      if let int = Int(first) {
        size = int
      } else {
        file = first
        if !command.isEmpty {
          size = try command.int()
        }
      }
    }
    
    
    
    let privateURL = "keys/\(file).private".dbURL
    let publicURL = "keys/\(file).public".dbURL
    
    let start = Time.abs
    let keys = Rsa(size: size)
    let end = Time.abs
    try? keys.privateKey.write(to: privateURL)
    try? keys.publicKey.write(to: publicURL)
    print("generated \(size) key for \(end-start) seconds")
    let value = UInt64.random()
    var data = Data(value)
    data.append(value)
    measure("encrypted for") {
      keys.lock(data: &data)
    }
    print("data size \(data.count)")
    measure("decrypted for") {
      try keys.unlock(data: &data)
    }
    
    
    print("created \(file).private \(keys.privateKey.count.bytesString)")
    print("created \(file).public \(keys.publicKey.count.bytesString)")
  }.description = "<filename: String?> <size: Int?> # generate rsa keys"
  
  terminal.add(function: "time") {
    print("\(Time.now.timeFormat): \(Time.now) (\(Time.abs))")
  }
  terminal.add(function: "current day") {
    print("\(Time.now / Time.day)")
  }
  terminal.add(function: "push fix") {
//    var fixed = 0
//    for user in users.array {
//      let tokens = Set(user.tokens)
//      if user.tokens.count > tokens.count {
//        fixed += user.tokens.count - tokens.count
//        user.tokens = Array(tokens)
//      }
//    }
//    print("fixed \(fixed) tokens")
  }
  terminal.add(advanced: "push") { command in
    if command.isEmpty {
      for (token,id) in pushManager.data {
        print("\(id): \(token)")
      }
    } else {
      let title = try command.string()
      let body = try? command.text()
      pushManager.pushAll(notification: .text(title, body))
    }
  }
  terminal.add(function: "connections") {
    for c in server.connections.values {
      if let c = c as? Connection {
        if let user = c.user {
          print("\(c.ip) \(c._handle) - \(user.id) \(user.name)")
        } else {
          print("\(c.ip) \(c._handle)")
        }
      } else {
        print("\(c.ip) - unknown")
      }
    }
  }
//  terminal.add(function: "connections force read") {
//    for c in server.connections.values {
//      newThread {
//        if let c = c as? Connection {
//          if let user = c.user {
//            print("\(c.ip) \(c._handle) - \(user.id) \(user.name)")
//          } else {
//            print("\(c.ip) \(c._handle)")
//          }
//        } else {
//          print("\(c.ip) - unknown")
//        }
//        try? c.ready()
//      }
//    }
//  }
  terminal.add(advanced: "decrypt") { command in
    let sPassword = try command.string()
    guard let password = UInt64(sPassword) else { throw command.error }
    let hex = try command.string()
    var data = hex.data
    data.decrypt(password: password)
    if let string = data.string {
      print(string)
    } else {
      print("cannot decrypt")
    }
  }
  terminal.add(withParameters: "encrypt") { command, params in
    let raw = params.contains("d")
    var text = try command.text()
    let password: UInt64 = .random()
    if !raw {
      let length = text.length
      text += String(repeating: " ", count: 8 - length % 8)
    }
    var data = text.data
    data.encrypt(password: password)
    print("password: 0x\(password.hex) \(password)")
    if raw {
      print(data.hexString2)
    } else {
      var array = [String]()
      for i in stride(from: 0, to: data.count, by: 8) {
        let chunk = data[i..<i+8]
        array.append("0x\(chunk.hexString2)")
      }
      print("[\(array.joined(separator: ","))]")
    }
  }
}

/*
 -user ( user info 10 )
 info
 password
 rename
 setPassword
 +disconnect
 
 -ne user ( user create )
 create
 list
 
 */

func printUsers(_ set: Set<Int>) {
  for id in set {
    printUser(id)
  }
  if set.isEmpty {
    print("empty")
  }
}
func printUsers(_ set: [Int]) {
  for id in set {
    printUser(id)
  }
  if set.isEmpty {
    print("empty")
  }
}
func printUser(_ id: Int) {
  if let user = users[id] {
    print("\(user.id) \(user.name)")
  } else {
    print("- unknown")
  }
}

func printEvents(_ set: Set<Int>) {
  let sorted = set.events.sorted { $0.id < $1.id }
  for event in sorted {
    printEvent(event.id)
  }
  if set.isEmpty {
    print("empty")
  }
}
func printEvents(_ set: [Int]) {
  let sorted = set.events.sorted { $0.id < $1.id }
  for event in sorted {
    printEvent(event.id)
  }
  if set.count > 0 {
    print("empty")
  }
}
func printEvent(_ id: Int) {
  if let event = events[id] {
    print("\(event.id) \(event.name) (\(event.privacy))")
  } else {
    print("- unknown")
  }
}

func selectedUser() throws -> User {
  if let user = User.selected {
    return user
  } else {
    print("user not selected")
    throw CmdError.noprint
  }
}
func selectedEvent() throws -> Event {
  if let event = Event.selected {
    return event
  } else {
    print("event not selected")
    throw CmdError.noprint
  }
}

extension User {
  static var selected: User?
  static let console = Console(name: "user")
}

extension Event {
  static var selected: Event?
  static let console = Console(name: "event")
}

private func userCommands() {
  let console = User.console
  console.add(function: "disconnect") {
    let user = try selectedUser()
    for connection in user.currentConnections {
      connection.disconnect()
    }
  }
  console.add(function: "connections") {
    let user = try selectedUser()
    print("\(user.currentConnections.count) connections")
    if !user.currentConnections.isEmpty {
      for connection in user.currentConnections {
        print(connection, " isSubscribed: \(connection.isSubscribed)")
        if !connection.subscriptions.isEmpty {
          print("- \(connection.subscriptions.count) subs:")
          for sub in connection.subscriptions {
            print(sub)
          }
        }
      }
    }
    print("\(user.currentDownloads.count) downloads")
    if !user.currentDownloads.isEmpty {
      for connection in user.currentDownloads {
        print(connection, " isSubscribed: \(connection.isSubscribed)")
        if !connection.subscriptions.isEmpty {
          print("- \(connection.subscriptions.count) subs:")
          for sub in connection.subscriptions {
            print(sub)
          }
        }
      }
    }
    
    print("\(user.currentUploads.count) uploads")
    if !user.currentUploads.isEmpty {
      for connection in user.currentUploads {
        print(connection, " isSubscribed: \(connection.isSubscribed)")
        if !connection.subscriptions.isEmpty {
          print("- \(connection.subscriptions.count) subs:")
          for sub in connection.subscriptions {
            print(sub)
          }
        }
      }
    }
  }
  console.add(function: "info") {
    let user = try selectedUser()
    var strings = [String]()
    user.print(main: &strings)
    user.print(publicProfile: &strings)
    user.print(privateProfile: &strings)
    user.print(serverPrivate: &strings)
    user.print(nonStorable: &strings)
    
    strings.forEach { print($0) }
  }
  console.add(function: "friends") {
    let user = try selectedUser()
    printUsers(user.friends)
    print("\(user.friends.count) friends")
  }
  console.add(function: "friends incoming") {
    let user = try selectedUser()
    printUsers(user.incoming)
    print("\n\(user.incoming.count) requests")
  }
  console.add(function: "friends outcoming") {
    let user = try selectedUser()
    printUsers(user.outcoming)
    print("\n\(user.outcoming.count) requests")
  }
  console.add(withParameters: "friend") { command, params in
    let user1, user2: User
    if params.contains("i") {
      user2 = try selectedUser()
      user1 = try command.user()
    } else {
      user1 = try selectedUser()
      user2 = try command.user()
    }
    user1.add(friend: user2, notify: true)
    if params.contains("f") {
      user2.add(friend: user1, notify: true)
    }
  }.description = "<id: Int> # f - autoaccept, i - incoming"
  console.add(withParameters: "unfriend") { command, params in
    let user1, user2: User
    if params.contains("i") {
      user2 = try selectedUser()
      user1 = try command.user()
    } else {
      user1 = try selectedUser()
      user2 = try command.user()
    }
    user1.remove(friend: user2, notify: true)
  }.description = "<id: Int> # i - incoming"
  console.add(function: "subscriptions") {
    let user = try selectedUser()
    printUsers(user.subscriptions)
    print("\n\(user.subscriptions.count) subscriptions")
  }
  console.add(function: "subscribers") {
    let user = try selectedUser()
    printUsers(user.subscribers)
    print("\n\(user.subscribers.count) subscribers")
  }
  console.add(advanced: "comment") { command in
    let user = try selectedUser()
    let event = try command.event()
    let text = try command.text()
    let message = Message(from: user.id, time: .now, body: text, chat: event.comments)
    event.comments.send(message: message)
  }
  console.add(advanced: "password") { command in
    let user = try selectedUser()
    if command.isEmpty {
      print(user.password)
    } else {
      let password = try command.int()
      user.password = UInt64(password)
      print("password changed")
    }
  }.description = "<id: Int><password: String?> # get/set password"
  console.add(advanced: "name") { command in
    let user = try selectedUser()
    if command.isEmpty {
      print(user.name)
    } else {
      let name = try command.text()
      user.rename(name: name, notify: true)
    }
  }
  console.add(advanced: "push") { command in
    let user = try selectedUser()
    if command.isEmpty {
      for token in user.tokens {
        print(token)
      }
    } else {
      let title = try command.string()
      let body = try? command.text()
      pushManager.push(to: user, notification: .text(title, body))
    }
  }
  console.add(advanced: "create") { command in
    let user = try selectedUser()
    let name = try command.text()
    let event = Event(id: events.count, name: name, owner: user.id)
    events.create(event: event, user: user, notify: true)
    print("created \(event.id)")
  }.description = "<name: String>"
  console.add(function: "events") {
    let user = try selectedUser()
    printEvents(Set(user.events))
  }
  console.add(advanced: "remove") { command in
    let user = try selectedUser()
    let name = try command.text()
    let events = user.events.events.filter { $0.name == name }
    for event in events {
      try event.remove(by: user, user: user, notify: true)
    }
  }
  console.add(advanced: "generate content") { command in
    let user = try selectedUser()
    let count = try command.int()
    var timeOffset: Double = 0
    for _ in 0..<count {
      let event = user.events.events.any
      timeOffset += 0.5
      wait(timeOffset) {
        generateContent(for: event)
      }
    }
  }
  
//  terminal.add(command: console)
  
  terminal.add(advanced: "hex") { command in
    let v = try command.string()
    guard let i = Int(v, radix: 16) else { throw CmdError.wrong }
    print(i)
  }
  terminal.add(advanced: "options") { command in
    let v = try command.int()
    var string = ""
    for i in 0..<8 {
      string += v[i] ? "1" : "0"
    }
    print(string)
  }
  
  terminal.add(advanced: "user") { command in
    let id = try command.int()
    if let user = users[id] {
      User.selected = user
      if command.isEmpty {
        console.name = user.name
        terminal.select(console: console)
      } else {
        try console.execute(command)
      }
    } else {
      print("user \(id) not found")
    }
  }.description = "<id: Int> # selects user for \"user\" commands"
  
}
private func eventCommands() {
  let console = Event.console
  console.add(advanced: "generate comments") { command in
    let event = try selectedEvent()
    let count = try command.int()
    let from = 0
    for _ in 0..<count {
      let text = String.random(count: .random(min: 1, max: 100), set: StringRange.az)
      event.comments.send(text: text, from: from)
    }
    print("sending comments to \(event.comments.subscribers.count)")
  }.description = "<count: Int>"
  
  console.add(function: "comments") {
    let event = try selectedEvent()
    let sorted = event.comments.messages.sorted(by: { $0.time < $1.time })
    print("\(sorted.count) comments. \(event.comments.isEnabled ? "enabled" : "disabled")")
    for comment in sorted {
      var text = ""
      if let user = users[comment.from] {
        text += "\(user.name): \(comment.body)"
      }
      print(text)
    }
  }
  
  console.add(function: "invited") {
    let event = try selectedEvent()
    printUsers(event.invited)
  }
  
  console.add(advanced: "views") { command in
    let event = try selectedEvent()
    let count = try command.int()
    event.views = count
  }
  console.add(advanced: "current") { command in
    let event = try selectedEvent()
    let count = try command.int()
    event.current = count
  }
  console.add(advanced: "rename") { command in
    let event = try selectedEvent()
    let name = try command.text()
    try event.rename(users[event.owner], name: name, notify: true)
    print("uninvited")
  }
  console.add(advanced: "invite") { command in
    let event = try selectedEvent()
    let user = try command.user()
    let owner = users[event.owner]!
    try event.invite(by: owner, user: user, notify: true)
    print("uninvited")
  }
  console.add(advanced: "uninvite") { command in
    let event = try selectedEvent()
    let user = try command.user()
    let owner = users[event.owner]!
    try event.remove(by: owner, user: user, notify: true)
    print("uninvited")
  }
  console.add(advanced: "start time") { command in
    let event = try selectedEvent()
    guard !command.isEmpty else {
      print(event.startTime.dateFormat(date: .full, time: .full))
      return
    }
    let year = Time(try command.int())
    var month = Time(0)
    guard year > 1970 && year < 2018 else { throw command.error }
    guard month >= 0 && month < 12 else { throw command.error }
    if !command.isEmpty {
      month = try Time(command.int())
    }
    let time: Time = year * .year + month * .month
    if event.endTime < time {
      event.endTime = time + .hour * 2
    }
    event.startTime = time
    _ = event.status
  }
  console.add(advanced: "end time") { command in
    let event = try selectedEvent()
    guard !command.isEmpty else {
      print(event.endTime.dateFormat(date: .full, time: .full))
      return
    }
    let year = Time(try command.int())
    var month = Time(0)
    guard year > 1970 && year < 2018 else { throw command.error }
    guard month >= 0 && month < 12 else { throw command.error }
    if !command.isEmpty {
      month = try Time(command.int())
    }
    let time: Time = year * .year + month * .month
    if event.startTime > time {
      event.startTime = time - .hour * 2
    }
    event.endTime = time
    _ = event.status
  }
  
  console.add(advanced: "owner") { command in
    if command.isEmpty {
      let event = try selectedEvent()
      printUser(event.owner)
    } else {
      let event = try selectedEvent()
      let user = try command.user()
      guard event.owner != user.id else { return }
      event.owner = user.id
      serverEvents.ownerChanged(event: event)
    }
  }
  console.add(function: "private") {
    let event = try selectedEvent()
    event.set(privacy: .private, notify: true)
  }
  console.add(function: "public") {
    let event = try selectedEvent()
    event.set(privacy: .public, notify: true)
  }
  
  console.add(function: "generate content") {
    let event = try selectedEvent()
    generateContent(for: event)
  }
  
  terminal.add(advanced: "event") { command in
    let id = try command.int()
    if let event = events[id] {
      Event.selected = event
      if command.isEmpty {
        console.name = event.name
        terminal.select(console: console)
      } else {
        try console.execute(command)
      }
    } else {
      print("event \(id) not found")
    }
    }.description = "<id: Int> # selects event for \"event\" commands"
}

private func generateContent(for event: Event) {
  let content = bots.randomPhoto
  event.add(content: content, notify: false, from: nil)
  event.lastContent = content
  serverEvents.newContent(event: event, content: content, ignore: nil)
  serverEvents.contentPreviewUploaded(event: event, content: content)
  serverEvents.contentUploaded(event: event, content: content)
}

private func print(_ text: String) {
  guard !text.isEmpty else { return }
  Swift.print(text)
}


extension Command {
  func user() throws -> User {
    let id = try int()
    guard let user = users[id] else {
      print("user \(id) not found")
      throw CmdError.noprint
    }
    return user
  }
  func event() throws -> Event {
    let id = try int()
    guard let event = events[id] else {
      print("event \(id) not found")
      throw CmdError.noprint
    }
    return event
  }
}









