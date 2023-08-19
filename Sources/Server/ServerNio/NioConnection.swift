//
//  NioConnection.swift
//  CNIOAtomics
//
//  Created by Dmitry on 07/03/2019.
//

import Dispatch
import SomeFunctions
import SomeData
import NIO
//-import SomeTcp
import NIOFoundationCompat

extension SomeSettings {
  public static var debugTcp = true
}
private func print(_ string: String) {
  guard SomeSettings.debugTcp else { return }
  Swift.print(string)
}

private extension DataReader {
  func last() -> Data? {
    guard count - position > 1 else { return nil }
    return data.subdata(in: position..<count)
  }
}

extension DataReader {
  func has(unusedBytes: Int) -> Bool {
    return count - position >= unusedBytes
  }
  func removeUsedBytes() {
    guard position > 0 else { return }
    data.removeSubrange(0..<position)
    position = 0
  }
  var packageSize: UInt32 {
    let start = position
    let end = position + 4
    guard end <= count else { return 0 }
    let slice = data[start..<end]
    return slice.convert()
  }
  
  func package() throws -> DataReader? {
    let packageSize = self.packageSize
    guard packageSize > 0 else { return nil }
    guard position + Int(packageSize) <= count else { return nil }
    
    position += 4
    let length = Int(packageSize) - 4
    let start = position
    let end = position + length
    guard end <= count else { throw corrupted }
    position = end
    let slice = data.subdata(in: start..<end)///data[start..<end]
    let reader = DataReader(data: slice)
    return reader
  }
}

extension DataWriter {
  func pack() {
    let binary = Data(UInt32(count))
    replace(at: 0, with: binary)
  }
}

class Reader {
  let file: NetFile
  var fileHandle: Foundation.FileHandle!
  unowned let connection: SomeConnection3
  var completion: ()->()
  var locker = NSLock()
  init(file: NetFile, connection: SomeConnection3, completion: @escaping ()->()) {
    self.file = file
    self.connection = connection
    self.completion = completion
    
  }
  func start() throws {
    locker.lock()
    defer { locker.unlock() }
    
    file.tempLocation.directory.create(subdirectories: true)
    file.tempLocation.create()
    fileHandle = try Foundation.FileHandle(forWritingTo: file.tempLocation.url)
    fileHandle.seek(toFileOffset: UInt64(file.completed))
    
    // делаем, чтобы file.isCompleted был false, пока файл не переместится
    file.completed -= 1
    
    if let data = connection.buffer.last() {
      print("tcp \(connection._handle): data received \(data.count) \(data[0..<4].hexString) (first bytes)")
      fileHandle.write(data)
      file.completed += Int64(data.count)
      check()
    }
    print("tcp \(connection._handle): initialized")
  }
  func received(data: Data) {
    print("tcp: data reading")
    locker.lock()
    defer { locker.unlock() }
    
    guard !file.isCancelled else {
      connection.disconnect()
      return }
    
    print("tcp \(connection._handle): data received \(data.count) \(data[data.count-4..<data.count].hexString)")
    fileHandle.write(data)
    file.completed += Int64(data.count)
    print("\(file.completed + 1)/\(file.total) (\(file.total - file.completed - 1))")
    check()
  }
  func check() {
    guard file.completed + 1 >= file.total else { return }
    print("uploaded")
    file.location.directory.create(subdirectories: true)
    file.tempLocation.move(to: file.location)
    file.completed += 1
    connection.disconnect()
    completion()
  }
  func done() {
    fileHandle.closeFile()
  }
}

public class ConnectionChain {
  func read(_ completion: (DataWriter)->()) -> Self {
    return self
  }
  func send(data: DataWriter, completion: ()->()) -> Self {
    return self
  }
}

open class SomeConnection3 {
  public static var readLength = 1024
  public static var printFileProgress = false
  public var isConnected: Bool { return connection.isActive }
  
  public var lastResponse: DataReader?
  public var lastRead: ((DataReader)throws->())?
  var reader: Reader?
  
  private var skey: UInt64 = 0
  private var rkey: UInt64 = 0
  
  var buffer = DataReader()
  var connection: Channel
  
  public var handle: ObjectIdentifier? {
    return connection.isActive ? _handle : nil
  }
  public var _handle: ObjectIdentifier {
    return ObjectIdentifier(connection)
  }
  var ip: String { return description }
  
  public init(channel: Channel) {
    connection = channel
  }
  
  open var sender: DataWriter {
    let writer = DataWriter()
    writer.data.append(UInt32(0))
    return writer
  }
  open func response() -> DataWriter {
    let writer = DataWriter()
    writer.data.append(UInt32(0))
    writer.append(UInt8(0))
    return writer
  }
  
  public var lastActivity: Time = .now
  
  public func read(success: @escaping (DataReader)throws->()) {
    if let data = lastResponse {
      print("tcp: read() have response")
      lastResponse = nil
      do {
        try success(data)
      } catch {
        disconnect()
      }
    } else {
      print("tcp: read() waiting for response")
      lastRead = success
    }
  }
  
  public func received(data: Data) throws {
    lastActivity = .now
    if let reader = reader {
      reader.received(data: data)
    } else {
      try appendBytes(data: data)
      while let package = try buffer.package() {
        print("tcp: constructed package \(package.count.bytesString)")
        decrypt(data: package)
        process(response: package)
      }
    }
  }
  
  
  private func appendBytes(data: Data) throws {
    print("tcp: reading")
    print("tcp \(self): received \(reader == nil) \(data.count) \(data.hexString)")
    buffer.data.append(data)
  }
  
  private func process(response: DataReader) {
    guard response.has(unusedBytes: 1) else { return }
    let type = try! response.uint8()
    if type == 0 {
      if let lastRead = lastRead {
        self.lastRead = nil
        do {
          try lastRead(response)
        } catch {
          disconnect()
        }
      } else {
        lastResponse = response
      }
    } else {
      pthread {
        try? self.notification(type: type, data: response)
      }
    }
  }
  
//  open func send(_ data: DataWriter) -> EventLoopFuture<Void> {
//    encrypt(data: data)
//    data.replace(at: 0, with: Data(UInt32(data.count)))
//    return send(data.data)
//  }
//  open func send(_ data: Data) -> EventLoopFuture<Void> {
//    var buffer = connection.allocator.buffer(capacity: data.count)
//    buffer.write(bytes: data)
//    return connection.writeAndFlush(buffer)
//  }
  
  open func tsend(_ data: DataWriter) {
    encrypt(data: data)
    data.replace(at: 0, with: Data(UInt32(data.count)))
    tsend(data.data)
  }
  open func tsend(_ data: Data) {
    var buffer = connection.allocator.buffer(capacity: data.count)
    buffer.write(bytes: data)
    connection.writeAndFlush(buffer, promise: nil)
  }
  
  open func request(constructor: (DataWriter) throws -> ()) rethrows {
    let data = sender
    try constructor(data)
    tsend(data)
  }
  open func response(constructor: (DataWriter) throws -> ()) rethrows {
    let data = response()
    try constructor(data)
    tsend(data)
  }
  
  // Read/write file
  open func read(_ file: NetFile, completion: @escaping ()->()) throws {
    reader = Reader(file: file, connection: self, completion: completion)
    do {
      try reader!.start()
    } catch {
      reader = nil
      throw error
    }
  }
  
  open func send(_ file: NetFile) throws {
    guard let handle = try? NIO.FileHandle(path: file.location.path) else { throw NetFileError.cantOpen }
    let start = Int(file.completed)
    let end = Int(file.location.fileSize)
    let region = FileRegion(fileHandle: handle, readerIndex: start, endIndex: end)
    let a = UInt64.random()
    Swift.print("""
      Sending file: \(a.hex)
      \(file.location.path)
      \(start)/\(end)
      """)
    let future = connection.writeAndFlush(region)
    future.whenComplete {
      Swift.print("File sent \(a.hex)")
      try? handle.close()
    }
    future.whenFailure { error in
      Swift.print("File failed \(a.hex) error: \(error)")
    }
  }
  
  @discardableResult
  open func disconnect() -> TCPError {
    connection.close(promise: nil)
    return .disconnected
  }
  
  open func connected() {
    
  }
  
  open func disconnected(by: ConnectionSide) {
    reader?.done()
    reader = nil
    lastRead = nil
  }
  
  open func notification(type: UInt8, data: DataReader) throws {
    
  }
  
  
  // encryption
  public func set(key: UInt64) {
    skey = key
    rkey = key
  }
  private func encrypt(data: DataWriter) {
    guard skey != 0 else { return }
    if data.count < 200 {
      print("encrypting:", data.data.hexString)
    } else {
      print("encrypting:", data.count.bytesString)
    }
    data.encrypt(password: skey)
    if data.count < 200 {
      print("encrypted:", data.data.hexString)
    }
  }
  private func decrypt(data: DataReader) {
    guard skey != 0 else { return }
    //      print("decrypting:", data.data.hexString)
    data.decrypt(password: skey, offset: 4)
    
    if data.count < 200 {
      print("decrypted:", data.data.hexString)
    } else {
      print("decrypted:", data.count.bytesString)
    }
  }
  private func encrypt(data: inout Data, offset: Int) {
    guard skey != 0 else { return }
    data.encrypt(password: skey, offset: offset)
  }
  private func decrypt(data: inout Data, offset: Int) {
    guard skey != 0 else { return }
    data.decrypt(password: skey, offset: offset)
  }
}

extension SomeConnection3: Hashable {
  public var hashValue: Int { return _handle.hashValue }
  public static func == (l:SomeConnection3,r:SomeConnection3) -> Bool { return l._handle == r._handle }
}

extension SomeConnection3: CustomStringConvertible {
  open var description: String { return connection.remoteAddress?.description ?? "----" }
}
