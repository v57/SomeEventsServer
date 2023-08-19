//
//  tcpServer.swift
//  faggot server
//
//  Created by Дмитрий Козлов on 26/01/16.
//  Copyright © 2016 anus. All rights reserved.
//

import Foundation

import SomeFunctions
import SomeData
//-import SomeTcp
import SomeBridge
import NIO

typealias Request = (_ data: DataReader) throws -> Void
let ok = Response.ok

struct SafeSet<T: Hashable> {
  let locker = NSLock()
  private var set = Set<T>()
  var count: Int { return set.count }
  func forEach(_ body: (T)->()) {
    locker.lock()
    set.forEach(body)
    locker.unlock()
  }
  mutating func insert(_ connection: T) {
    locker.lock()
    set.insert(connection)
    locker.unlock()
  }
  mutating func remove(_ connection: T) {
    locker.lock()
    set.remove(connection)
    locker.unlock()
  }
}

func runLocalServer() {
//  do {
//    try localServer.listen()
//    pthread {
//      do {
//        while true {
//          let socket = try localServer.accept()
//          print("\(socket) connected")
//          pthread {
//            defer { socket.disconnect() }
//            do {
//              let data = try socket.read(1024)
//              let command = data.string.trimmingCharacters(in: .whitespacesAndNewlines)
//              guard !command.isEmpty else { return }
//              print(command)
//              terminal.run(command)
//            } catch {}
//          }
//        }
//      } catch {
//        print("local server error:", String(describing: error))
//      }
//    }
//  } catch {
//    print("local server error:", String(describing: error))
//  }
}

class Server: SomeServer2 {
  override func received(data: Data, client: SomeConnection3) {
    super.received(data: data, client: client)
    obamacare.anyActivity = true
  }
  override func connection(with socket: Channel) -> SomeConnection3 {
    let c = Connection(channel: socket)
    c.set(key: 0xc61b44fc24ebfd2c)
    return c
  }
  override func process(disconnected client: SomeConnection3) {
    super.process(disconnected: client)
    if connections.count == 1 {
      db.save()
      obamacare.anyActivity = false
    }
  }
  override func process(connected client: SomeConnection3) {
    guard let client = client as? Connection else { return }
    client.read(success: client.authorize)
  }
}

//func runServer() {
//  print("starting server at \(serverAddress.ip):\(serverAddress.port)")
//  do {
//    try server.listen()
//    pthread {
//      do {
//        while true {
//          let socket = try server.accept()
//          print("\(socket) connected")
//          ghosts.insert(socket)
//          
//          pthread {
//            ghosts.remove(socket)
//            let client = Connection(client: socket)
//            client.stats = db.stats
//            
//            connections.insert(client)
//            
//            thread.lock()
//            client.connected()
//            thread.unlock()
//            
//            do {
//              try client.authorize()
//              try client.listen()
//            } catch TCPError.disconnected {
//              print("\(client) disconnected")
//            } catch {
//              print("\(client) disconnected: \(error)")
//              client.disconnect()
//            }
//            
//            connections.remove(client)
//          }
//        }
//      } catch {
//        print(String(describing: error))
//      }
//    }
//  } catch {
//    print(String(describing: error))
//  }
//}

enum ConnectionType: UInt8 {
  case unauthorized, normal, download, upload
}

class Connection: SomeConnection3 {
  var user: User!
  var connectionType: ConnectionType = .unauthorized
  var subscriptions = Set<Subscription>()
  let subLock = NSLock()
  var version: Int = 0
  
  var isSubscribed = false {
    didSet {
      guard isSubscribed != oldValue else { return }
      if isSubscribed {
        user.currentConnections.insert(self)
      } else {
        user.currentConnections.remove(self)
      }
    }
  }
  
  func tsend(response: Response) {
    let data = self.response()
    data.append(response)
    tsend(data)
  }
  func response(_ message: Response) -> DataWriter {
    let data = self.response()
    data.append(message)
    return data
  }
  
  override func disconnected(by: ConnectionSide) {
    super.disconnected(by: by)
    if let user = user {
      thread.lock()
      switch connectionType {
      case .normal:
        user.currentConnections.remove(self)
        print("disabling by closing (\(subscriptions.count))")
        subscriptions.forEach { $0.disable(connection: self) }
        
        isSubscribed = false
      case .download: user.currentDownloads.remove(self)
      case .upload: user.currentUploads.remove(self)
      case .unauthorized: break
      }
      thread.unlock()
      print("\(user.name) disconnected")
    } else {
      print("\(self) disconnected")
    }
    
    
  }
  func setDownload(user: User) {
    self.user = user
    self.connectionType = .download
    self.user.currentDownloads.insert(self)
  }
  func setUpload(user: User) {
    self.user = user
    self.connectionType = .upload
    self.user.currentUploads.insert(self)
  }
  func set(user: User) {
    self.user = user
    isSubscribed = true
  }
  override func notification(type: UInt8, data: DataReader) throws {
    guard let command = type.ccmd else {
      print("received unknown command: \(type)")
      return
    }
    print("received \(data.count) bytes")
    guard connectionType == .normal else {
      print("received command from \(connectionType) connection")
      return }
    do {
      try api.run(command: command, data: data, connection: self)
    } catch {
      if let response = error as? Response {
        tsend(response: response)
      }
    }
  }
  
  
  override func read(_ file: NetFile, completion: @escaping ()->()) throws {
    monitor.uploadStarted()
    defer { monitor.uploadEnded() }
    try super.read(file, completion: completion)
  }
  
  override func send(_ file: NetFile) throws {
    monitor.downloadStarted()
    defer { monitor.downloadEnded() }
    try super.send(file)
  }
  
//  func authorize(data: DataReader) throws {
//    let options: ConnectionSecurity = try data.next()
//    let command: cmd = try data.next()
//    if command == .notification {
//      let q: UInt64 = .random()
//      let a: UInt64 = .seed(skey, q)
//      let d = self.response()
//      d.append(q)
//      d.append(AppVersion.server)
//      d.append(AppVersion.minimum)
//      print("authorizing")
//      print("q: \(q)")
//      try self.send(d)
//      self.set(key: a &+ 0x65b6a144cc404b04)
//      self.read { data in
//        let answer = try data.uint64()
//        if answer != a {
//          print("wrong answer: \(answer)")
//          print("q: \(q) a: \(a)")
//          print("not authorized")
//          self.disconnect()
//        } else {
//          print("authorized")
//        }
//      }
//    } else {
//      let id = try data.int()
//      let password = try data.uint64()
//      self.user = try users.login(id: id, password: password)
//      if let function = api.fileFunctions[command] {
//        try function(self, data)
//      } else {
//        print("api error: file function \(command) not found")
//      }
//    }
//  }
  
//  func rsaAuthorize(data: DataReader) throws {
//    let publicKey: Data = try data.next()
//    let keys = Keys(public: publicKey)
//
//    let (key,index) = keyManager.create()
//    var keyData = Data(key)
//    keys.lock(data: &keyData)
//
//    let data = response(.ok)
//    data.append(keyData)
//    data.append(index)
//
//    tsend(data)
//    set(key: key)
//    connectionType = .normal
//  }
  func rsa2Authorize(data: DataReader) throws {
    let publicKey: Data = try data.next()
    let keys = try Rsa(publicKey: publicKey)
    
    let (key,index) = keyManager.create()
    var keyData = Data(key)
    keys.lock(data: &keyData)
    
    let data = response(.ok)
    data.append(keyData)
    data.append(index)
    
    tsend(data)
    set(key: key)
    connectionType = .normal
  }
  
  func keyAuthorize(data: DataReader) throws {
    let index = try data.int()
    if let key = keyManager[index] {
      tsend(response: .ok)
      set(key: key)
      connectionType = .normal
    } else {
      throw Response.keyOutdated
    }
  }
  
  func fastAuthorize(data: DataReader) throws {
    let index = try data.int()
    guard let key = keyManager[index] else { throw Response.keyOutdated }
    
    set(key: key)
    data.decrypt(password: key)
    
    
    let options: ConnectionOptions.Set = try data.next()
    if options.contains(.debug) {
      let dbVersion = try data.int()
      if versions.dbVersion != dbVersion {
        let rdata = response(.wrongDB)
        rdata.append(versions.dbVersion)
        throw disconnect()
      }
      guard versions.dbVersion == dbVersion else { throw Response.wrongDB }
    }
    
    if options.contains(.auth) {
      let id: Int = try data.int()
      let password: UInt64 = try data.uint64()
      user = try users.login(id: id, password: password)
    }
    
    if options.contains(.file) {
      guard user != nil else { throw Response.requestCorrupted }
      connectionType = .normal
      let command: cmd = try data.next()
      try api.run(file: command, data: data, connection: self)
    } else if let user = user {
      let rdata = response(.ok)
      
      thread.lock()
      let isMainLoaded = try data.bool()
      
      let mainVersion = try data.uint16()
      let shouldUpdateMain = mainVersion != user.mainVersion || !isMainLoaded
      rdata.append(shouldUpdateMain)
      if shouldUpdateMain {
        user.write(main: rdata)
      }
      
      let publicVersion = try data.uint16()
      let shouldUpdatePublic = publicVersion != user.publicProfileVersion || !isMainLoaded
      rdata.append(shouldUpdatePublic)
      if shouldUpdatePublic {
        rdata.append(user.publicProfileVersion)
        user.events.eventMain(data: rdata)
      }
      
      
      let privateVerison = try data.int()
      let shouldUpdatePrivate = privateVerison != user.privateProfileVersion || !isMainLoaded
      rdata.append(shouldUpdatePrivate)
      if shouldUpdatePrivate {
        rdata.append(user.privateOptions)
        rdata.append(user.privateProfileVersion)
        rdata.append(user.friends)
        rdata.append(user.outcoming)
        rdata.append(user.incoming)
        rdata.append(user.subscribers.count)
        rdata.append(user.subscriptions)
        rdata.append(user.favorite)
      }
      
      if user.isModerator {
        rdata.append(reports.count)
        rdata.append(reports.uncheckedCount)
      }
      thread.unlock()
      
      let count = try data.uint8()
      if count > 0 {
        var subs = Set<Subscription>()
        for _ in 0..<count {
          let subscription = try data.subscription()
          subs.insert(subscription)
        }
        thread.lock()
        subscriptions = subs
        subs.forEach { $0.enable(connection: self) }
        
        rdata.append(subs.count)
        for sub in subs {
          sub.subscribe(connection: self, data: rdata)
        }
        thread.unlock()
      }
      connectionType = .normal
      
      tsend(rdata)
      
      print("\(user.name) connected")
    } else {
      print("\(self) connected")
    }
  }
  
  func authorize(data: DataReader) throws {
    version = try data.next()
    guard version >= AppVersion.minimum else { throw Response.outdated }
    
    let security: ConnectionSecurity = try data.next()
    switch security {
    case .rsa:
      throw Response.outdated
//      try rsaAuthorize(data: data)
    case .key:
      try keyAuthorize(data: data)
    case .fast:
      try fastAuthorize(data: data)
    case .rsa2:
      try rsa2Authorize(data: data)
    }
    
  }
}

typealias ServerFunction = (_ connection: Connection, _ data: DataReader) throws -> Void
class API {
  var authFunctions = [cmd: ServerFunction]()
  var unauthFunctions = [cmd: ServerFunction]()
  var moderatorFunctions = [cmd: ServerFunction]()
  var adminFunctions = [cmd: ServerFunction]()
  var fileFunctions = [cmd: ServerFunction]()
  init() {
    auth(commands: &authFunctions)
    unauth(commands: &unauthFunctions)
    files(commands: &unauthFunctions)
    ceo.managers.forEach { manager in
      guard manager is ApiManager else { return }
      (manager as? AuthCommands)?.auth(commands: &authFunctions)
      (manager as? UnauthCommands)?.unauth(commands: &unauthFunctions)
      (manager as? FileCommands)?.files(commands: &fileFunctions)
      (manager as? AdminCommands)?.admin(commands: &adminFunctions)
      (manager as? ModeratorCommands)?.moderator(commands: &moderatorFunctions)
    }
    cmd.forEach { command in
      var contains = false
      check(command, authFunctions, &contains)
      check(command, unauthFunctions, &contains)
      check(command, moderatorFunctions, &contains)
      check(command, adminFunctions, &contains)
      check(command, fileFunctions, &contains)
      if !contains {
        print("cmd.\(command) not connected")
      }
    }
  }
  func check(_ command: cmd, _ data: [cmd: ServerFunction], _ to: inout Bool) {
    guard !to else { return }
    if data[command] != nil {
      to = true
    }
  }
  func run(file command: cmd, data: DataReader, connection: Connection) throws {
    if let function = api.fileFunctions[command] {
      try function(connection, data)
    } else {
      print("api error: file function \(command) not found")
    }
  }
  func run(command: cmd, data: DataReader, connection: Connection) throws {
    var function: ServerFunction?
    var suffix = ""
    if let user = connection.user {
      thread.lock()
      if user.isAdmin {
        set(function: &function, from: adminFunctions, with: command)
        suffix += " -admin"
      }
      if user.isModerator {
        set(function: &function, from: moderatorFunctions, with: command)
        suffix += " -moderator"
      }
      thread.unlock()
      set(function: &function, from: authFunctions, with: command)
      suffix += " -\(user.name)"
    } else {
      set(function: &function, from: unauthFunctions, with: command)
      suffix += " -unsigned"
    }
    
    print("cmd.\(command)\(suffix)")
    try function?(connection, data)
    if function == nil {
      print("api error: command \(command) not found")
    }
  }
  func set(function: inout ServerFunction?, from api: [cmd: ServerFunction], with command: cmd) {
    guard function == nil else { return }
    function = api[command]
  }
}
func spam(data: DataWriter, to cs: Array<Connection>) {
  guard !cs.isEmpty else { return }
  if let command = data.data[4].scmd {
    print("spamming \(command) to \(cs.count) users")
  } else {
    print("spamming UNKNOWN to \(cs.count) users")
  }
  data.spam()
  for c in cs where c.isConnected {
    let copy = data.copy()
    c.tsend(copy)
  }
}

func spam(data: DataWriter, to cs: Set<Connection>) {
  guard !cs.isEmpty else { return }
  if let command = data.data[4].scmd {
    print("spamming \(command) to \(cs.count) users")
  } else {
    print("spamming UNKNOWN to \(cs.count) users")
  }
  data.spam()
  for c in cs where c.isConnected {
    let copy = data.copy()
    c.tsend(copy)
  }
}

extension Set where Element == Connection {
  func splitByVersion(splitted: (Int, [Connection])->()) {
    var dictionary = DictionaryOfArray<Int, Connection>()
    for connection in self {
      dictionary.append(connection, at: connection.version)
    }
    dictionary.data.forEach { splitted($0, $1) }
  }
}

struct DictionaryOfArray<Key,Element> where Key: Hashable {
  var data = [Key: [Element]]()
  mutating func append(_ element: Element, at key: Key) {
    if data[key] != nil {
      data[key]!.append(element)
    } else {
      data[key] = [element]
    }
  }
}

