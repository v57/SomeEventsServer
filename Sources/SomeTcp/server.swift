//
//  server.swift
//  Server
//
//  Created by Дмитрий Козлов on 6/9/17.
//
//

import Foundation
import SomeFunctions


open class SomeServer {
  public var connections = [Int32: SomeConnection2]()
  public var buffer = [UInt8](repeating: 0, count: 8192)
  public var socket: TCPServer
  public var isRunning = false
  
  public init(port: Int) {
    socket = TCPServer(ip: "0.0.0.0", port: port)
  }
  
  open func start() throws {
    isRunning = true
    do {
      print("starting server at: \(socket.ip):\(socket.port)")
      try socket.listen()
      pthread {
        self.started()
      }
    } catch {
      print("starting failed: \(error)")
      throw error
    }
  }
  func started() {
    while isRunning {
      self.run()
      sleep(1)
    }
  }
  
  open func failed(error: Error) {
    try? socket.close()
  }
  
  open func connection(with socket: TCPClient) -> SomeConnection2 {
    return SomeConnection2(client: socket)
  }
  
  open func close() throws {
    try socket.close()
    throw TCPError.disconnected
  }
  
  
  func keventCreate(fd: Int32) -> kevent {
    var kev = kevent()
    kev.ident = UInt(fd)
    kev.filter = Int16(EVFILT_READ)
    kev.flags = UInt16(EV_ADD)
    kev.udata = UnsafeMutableRawPointer(bitPattern: UInt(0))
    return kev
  }
  func keventDelete(fd: Int32) -> kevent {
    var kev = kevent()
    kev.ident = UInt(fd)
    kev.filter = Int16(EVFILT_READ)
    kev.flags = UInt16(EV_DELETE)
    kev.udata = UnsafeMutableRawPointer(bitPattern: UInt(0))
    return kev
  }
  
  func createList() -> [kevent] {
    return .init(repeating: kevent(), count: 32)
  }
  
  func run() {
    var evList = createList()
    
    var count: Int32 = 0
    let kq = kqueue()
    var serverKev = keventCreate(fd: socket._handle)
    guard kq > 0 else {
      print("cannot create kqueue")
      return }
    guard kevent(kq, &serverKev, 1, nil, 0, nil) != -1 else {
      print("cannot set kevent for server socket")
      return }
    
    while true {
      
      if SomeSettings.debugTcp {
        print("selecting \(connections.count+1) sockets")
      }
      count = kevent(kq, nil, 0, &evList, 32, nil)
      if SomeSettings.debugTcp {
        print("selected \(count)/\(connections.count+1)")
      }
      
      guard count >= 0 else {
        error("select failed")
        return
      }
      guard count > 0 else { continue }
      
      for kEvent in evList.first(Int(count)) {
        let flags = Int32(kEvent.flags)
        let fd = Int32(kEvent.ident)
        if fd == socket._handle {
          guard let socket = try? self.socket.accept() else { return }
          let connection = self.connection(with: socket)
          connections[socket._handle] = connection
          process(connected: connection)
          var event = keventCreate(fd: socket._handle)
          assert(kevent(kq, &event, 1, nil, 0, nil) != -1)
        } else if let socket = connections[fd] {
          let isDisconnected = (flags & EV_EOF > 0)
          if isDisconnected {
            Darwin.close(socket._handle)
            socket.disconnect()
            process(disconnected: socket)
            connections[fd] = nil
            // Socket is automatically removed from the kq by the kernel.
          } else {
            process(read: socket)
          }
        } else {
          print("can't find selected socket \(fd)")
        }
      }
    }
  }
  
  open func tick() throws {
    
  }
  
  open func process(connected client: SomeConnection2) {
    print(client.port,"connected")
  }
  
  open func process(disconnected client: SomeConnection2) {
    print(client.port,"disconnected")
  }
  
  open func process(read client: SomeConnection2) {
    try? client.ready()
  }
  open func stop() {}
  func error(_ description: String) {
    let error = String(validatingUTF8: strerror(errno)) ?? "Error: \(errno)"
    print("\(description): \(error)")
  }
}

