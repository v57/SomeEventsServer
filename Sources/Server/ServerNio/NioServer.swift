//
//  NioServer.swift
//  CNIOAtomics
//
//  Created by Dmitry on 07/03/2019.
//

import Foundation
import NIO

open class SomeServer2: ChannelInboundHandler {
  public typealias InboundIn = ByteBuffer
  public typealias OutboundOut = ByteBuffer
  
  public var connections = [ObjectIdentifier: SomeConnection3]()
  public var isRunning = false
  
  var port: Int
  var channel: Channel!
  let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
  let bootstrap: ServerBootstrap
  public init(port: Int) {
    self.port = port
    bootstrap = ServerBootstrap(group: group)
      
    _ = bootstrap
      // Specify backlog and enable SO_REUSEADDR for the server itself
      .serverChannelOption(ChannelOptions.backlog, value: 256)
      .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
      
      // Set the handlers that are applied to the accepted Channels
      .childChannelInitializer { channel in
        // Add handler that will buffer data until a \n is received
        channel.pipeline.add(handler: self)
      }
      
      // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
      .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
      .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
      .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
      .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
  }
  
  open func start() throws {
    isRunning = true
    do {
      print("starting server at: 0.0.0.0:\(port)")
      channel = try bootstrap.bind(host: "0.0.0.0", port: port).wait()
    } catch {
      print("starting failed: \(error)")
      throw error
    }
  }
  // All access to connections is guarded by channelsSyncQueue.
  private let channelsSyncQueue = DispatchQueue(label: "channelsQueue")
  
  public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
    try? received(data: _data(data), client: connection(ctx))
  }
  
  func _data(_ data: NIOAny) -> Data {
    var data = self.unwrapInboundIn(data)
    return data.readData(length: data.readableBytes)!
  }
  
  private func connection(_ ctx: ChannelHandlerContext) throws -> SomeConnection3 {
    let id = ObjectIdentifier(ctx.channel)
    guard let connection = connections[id] else { throw notFound }
    return connection
  }
  
  public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
    print("error: ", error)
    
    // As we are not really interested getting notified on success or failure we just pass nil as promise to
    // reduce allocations.
    ctx.close(promise: nil)
  }
  
  public func channelActive(ctx: ChannelHandlerContext) {
    let channel = ctx.channel
    self.channelsSyncQueue.async {
      let connection = self.connection(with: channel)
      self.connections[ObjectIdentifier(channel)] = connection
      self.process(connected: connection)
    }
  }
  
  public func channelInactive(ctx: ChannelHandlerContext) {
    let channel = ctx.channel
    let id = ObjectIdentifier(ctx.channel)
    self.channelsSyncQueue.async {
      guard let c = self.connections[id] else { return }
      self.process(disconnected: c)
      self.connections[ObjectIdentifier(channel)] = nil
    }
  }
  
  private func writeToAll(connections: [ObjectIdentifier: Channel], allocator: ByteBufferAllocator, message: String) {
    var buffer =  allocator.buffer(capacity: message.utf8.count)
    buffer.write(string: message)
    self.writeToAll(connections: connections, buffer: buffer)
  }
  
  private func writeToAll(connections: [ObjectIdentifier: Channel], buffer: ByteBuffer) {
    connections.forEach { $0.value.writeAndFlush(buffer, promise: nil) }
  }
  
  open func failed(error: Error) {
    stop()
  }
  
  open func connection(with socket: Channel) -> SomeConnection3 {
    return SomeConnection3(channel: socket)
  }
  func close() {
    try! group.syncShutdownGracefully()
  }
  
  func run() {
    //    var evList = createList()
    //
    //    var count: Int32 = 0
    //    let kq = kqueue()
    //    var serverKev = keventCreate(fd: socket._handle)
    //    guard kq > 0 else {
    //      print("cannot create kqueue")
    //      return }
    //    guard kevent(kq, &serverKev, 1, nil, 0, nil) != -1 else {
    //      print("cannot set kevent for server socket")
    //      return }
    //
    //    while true {
    //
    //      if SomeSettings.debugTcp {
    //        print("selecting \(connections.count+1) sockets")
    //      }
    //      count = kevent(kq, nil, 0, &evList, 32, nil)
    //      if SomeSettings.debugTcp {
    //        print("selected \(count)/\(connections.count+1)")
    //      }
    //
    //      guard count >= 0 else {
    //        error("select failed")
    //        return
    //      }
    //      guard count > 0 else { continue }
    //
    //      for kEvent in evList.first(Int(count)) {
    //        let flags = Int32(kEvent.flags)
    //        let fd = Int32(kEvent.ident)
    //        if fd == socket._handle {
    //          guard let socket = try? self.socket.accept() else { return }
    //          let connection = self.connection(with: socket)
    //          connections[socket._handle] = connection
    //          process(connected: connection)
    //          var event = keventCreate(fd: socket._handle)
    //          assert(kevent(kq, &event, 1, nil, 0, nil) != -1)
    //        } else if let socket = connections[fd] {
    //          let isDisconnected = (flags & EV_EOF > 0)
    //          if isDisconnected {
    //            Darwin.close(socket._handle)
    //            socket.disconnect()
    //            process(disconnected: socket)
    //            connections[fd] = nil
    //            // Socket is automatically removed from the kq by the kernel.
    //          } else {
    //            process(read: socket)
    //          }
    //        } else {
    //          print("can't find selected socket \(fd)")
    //        }
    //      }
    //    }
  }
  
  open func process(connected client: SomeConnection3) {
    print(client,"connected")
  }
  
  open func process(disconnected client: SomeConnection3) {
    print(client,"disconnected")
  }
  
  open func received(data: Data, client: SomeConnection3) {
    try? client.received(data: data)
  }
  open func stop() {}
  func error(_ description: String) {
    let error = String(validatingUTF8: strerror(errno)) ?? "Error: \(errno)"
    print("\(description): \(error)")
  }
  
  
  //  // All access to connections is guarded by channelsSyncQueue.
  //  private let channelsSyncQueue = DispatchQueue(label: "channelsQueue")
  //  private var connections: [ObjectIdentifier: Channel] = [:]
  //
  //  public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
  //    let id = ObjectIdentifier(ctx.channel)
  //    var read = self.unwrapInboundIn(data)
  //
  //    // 64 should be good enough for the ipaddress
  //    var buffer = ctx.channel.allocator.buffer(capacity: read.readableBytes + 64)
  //    buffer.write(string: "(\(ctx.remoteAddress!)) - ")
  //    buffer.write(buffer: &read)
  //    self.channelsSyncQueue.async {
  //      // broadcast the message to all the connected clients except the one that wrote it.
  //      self.writeToAll(connections: self.connections.filter { id != $0.key }, buffer: buffer)
  //    }
  //  }
  //
  //  public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
  //    print("error: ", error)
  //
  //    // As we are not really interested getting notified on success or failure we just pass nil as promise to
  //    // reduce allocations.
  //    ctx.close(promise: nil)
  //  }
  //
  //  public func channelActive(ctx: ChannelHandlerContext) {
  //    let remoteAddress = ctx.remoteAddress!
  //    let channel = ctx.channel
  //    self.channelsSyncQueue.async {
  //      // broadcast the message to all the connected clients except the one that just became active.
  //      self.writeToAll(connections: self.connections, allocator: channel.allocator, message: "(ChatServer) - New client connected with address: \(remoteAddress)\n")
  //
  //      self.connections[ObjectIdentifier(channel)] = channel
  //    }
  //
  //    var buffer = channel.allocator.buffer(capacity: 64)
  //    buffer.write(string: "(ChatServer) - Welcome to: \(ctx.localAddress!)\n")
  //    ctx.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
  //  }
  //
  //  public func channelInactive(ctx: ChannelHandlerContext) {
  //    let channel = ctx.channel
  //    self.channelsSyncQueue.async {
  //      if self.connections.removeValue(forKey: ObjectIdentifier(channel)) != nil {
  //        // Broadcast the message to all the connected clients except the one that just was disconnected.
  //        self.writeToAll(connections: self.connections, allocator: channel.allocator, message: "(ChatServer) - Client disconnected\n")
  //      }
  //    }
  //  }
}
//
//private let newLine = "\n".utf8.first!
//
///// Very simple example codec which will buffer inbound data until a `\n` was found.
//final class LineDelimiterCodec: ByteToMessageDecoder {
//  public typealias InboundIn = ByteBuffer
//  public typealias InboundOut = ByteBuffer
//
//  public var cumulationBuffer: ByteBuffer?
//
//  public func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
//    let readable = buffer.withUnsafeReadableBytes { $0.index(of: newLine) }
//    if let r = readable {
//      ctx.fireChannelRead(self.wrapInboundOut(buffer.readSlice(length: r + 1)!))
//      return .continue
//    }
//    return .needMoreData
//  }
//}
//
///// This `ChannelInboundHandler` demonstrates a few things:
/////   * Synchronisation between `EventLoop`s.
/////   * Mixing `Dispatch` and SwiftNIO.
/////   * `Channel`s are thread-safe, `ChannelHandlerContext`s are not.
/////
///// As we are using an `MultiThreadedEventLoopGroup` that uses more then 1 thread we need to ensure proper
///// synchronization on the shared state in the `ChatHandler` (as the same instance is shared across
///// child `Channel`s). For this a serial `DispatchQueue` is used when we modify the shared state (the `Dictionary`).
///// As `ChannelHandlerContext` is not thread-safe we need to ensure we only operate on the `Channel` itself while
///// `Dispatch` executed the submitted block.
//final class ChatHandler: ChannelInboundHandler {
//  public typealias InboundIn = ByteBuffer
//  public typealias OutboundOut = ByteBuffer
//
//  // All access to connections is guarded by channelsSyncQueue.
//  private let channelsSyncQueue = DispatchQueue(label: "channelsQueue")
//  private var connections: [ObjectIdentifier: Channel] = [:]
//
//  public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
//    let id = ObjectIdentifier(ctx.channel)
//    var read = self.unwrapInboundIn(data)
//
//    // 64 should be good enough for the ipaddress
//    var buffer = ctx.channel.allocator.buffer(capacity: read.readableBytes + 64)
//    buffer.write(string: "(\(ctx.remoteAddress!)) - ")
//    buffer.write(buffer: &read)
//    self.channelsSyncQueue.async {
//      // broadcast the message to all the connected clients except the one that wrote it.
//      self.writeToAll(connections: self.connections.filter { id != $0.key }, buffer: buffer)
//    }
//  }
//
//  public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
//    print("error: ", error)
//
//    // As we are not really interested getting notified on success or failure we just pass nil as promise to
//    // reduce allocations.
//    ctx.close(promise: nil)
//  }
//
//  public func channelActive(ctx: ChannelHandlerContext) {
//    let remoteAddress = ctx.remoteAddress!
//    let channel = ctx.channel
//    self.channelsSyncQueue.async {
//      // broadcast the message to all the connected clients except the one that just became active.
//      self.writeToAll(connections: self.connections, allocator: channel.allocator, message: "(ChatServer) - New client connected with address: \(remoteAddress)\n")
//
//      self.connections[ObjectIdentifier(channel)] = channel
//    }
//
//    var buffer = channel.allocator.buffer(capacity: 64)
//    buffer.write(string: "(ChatServer) - Welcome to: \(ctx.localAddress!)\n")
//    ctx.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
//  }
//
//  public func channelInactive(ctx: ChannelHandlerContext) {
//    let channel = ctx.channel
//    self.channelsSyncQueue.async {
//      if self.connections.removeValue(forKey: ObjectIdentifier(channel)) != nil {
//        // Broadcast the message to all the connected clients except the one that just was disconnected.
//        self.writeToAll(connections: self.connections, allocator: channel.allocator, message: "(ChatServer) - Client disconnected\n")
//      }
//    }
//  }
//
//  private func writeToAll(connections: [ObjectIdentifier: Channel], allocator: ByteBufferAllocator, message: String) {
//    var buffer =  allocator.buffer(capacity: message.utf8.count)
//    buffer.write(string: message)
//    self.writeToAll(connections: connections, buffer: buffer)
//  }
//
//  private func writeToAll(connections: [ObjectIdentifier: Channel], buffer: ByteBuffer) {
//    connections.forEach { $0.value.writeAndFlush(buffer, promise: nil) }
//  }
//}
//
//private let handler = ChatHandler()
//class ServerNio {
//  func stop() {
//    try! group.syncShutdownGracefully()
//  }
//  let channel: Channel
//  let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
//  init(port: Int) throws {
//    let bootstrap = ServerBootstrap(group: group)
//      // Specify backlog and enable SO_REUSEADDR for the server itself
//      .serverChannelOption(ChannelOptions.backlog, value: 256)
//      .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
//
//      // Set the handlers that are applied to the accepted Channels
//      .childChannelInitializer { channel in
//        // Add handler that will buffer data until a \n is received
//        channel.pipeline.add(handler: LineDelimiterCodec()).then { v in
//          // It's important we use the same handler for all accepted connections. The ChatHandler is thread-safe!
//          channel.pipeline.add(handler: handler)
//        }
//      }
//
//      // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
//      .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
//      .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
//      .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
//      .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
//    channel = try bootstrap.bind(host: "0.0.0.0", port: port).wait()
//  }
//}
