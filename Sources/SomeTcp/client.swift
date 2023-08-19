//
//  client.swift
//  Server
//
//  Created by Дмитрий Козлов on 6/9/17.
//
//

import Foundation
import Dispatch
import SomeFunctions
import SomeData

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

class Reader {
  let file: NetFile
  var fileHandle: FileHandle!
  unowned let connection: SomeConnection2
  var completion: ()->()
  var locker = NSLock()
  init(file: NetFile, connection: SomeConnection2, completion: @escaping ()->()) {
    self.file = file
    self.connection = connection
    self.completion = completion
    
  }
  func start() throws {
    locker.lock()
    defer { locker.unlock() }
    
    file.tempLocation.directory.create(subdirectories: true)
    file.tempLocation.create()
    fileHandle = try FileHandle(forWritingTo: file.tempLocation.url)
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
  func ready() {
    print("tcp: data reading")
    locker.lock()
    defer { locker.unlock() }
    
    guard !file.isCancelled else {
      connection.disconnect()
      return }
    do {
      let data = try connection.read(100.kb)
      print("tcp \(connection._handle): data received \(data.count) \(data[data.count-4..<data.count].hexString)")
      fileHandle.write(data)
      file.completed += Int64(data.count)
      print("\(file.completed + 1)/\(file.total) (\(file.total - file.completed - 1))")
      check()
    } catch {}
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

open class SomeConnection2 {
  public static var readLength = 1024
  public static var printFileProgress = false
  public var isConnected: Bool { return connection.isConnected }
  
  public var lastResponse: DataReader?
  public var lastRead: ((DataReader)throws->())?
  var reader: Reader?
  
  private var skey: UInt64 = 0
  private var rkey: UInt64 = 0
  
  var buffer = DataReader()
  var connection: TCPClient
  
  public var handle: Int32? {
    return connection.handle
  }
  public var _handle: Int32 {
    return connection._handle
  }
  public var ip: String { return connection.ip }
  public var port: Int { return connection.port }
  
  public init(client: TCPClient) {
    connection = client
    connection.connected = { [unowned self] in
      self.connected()
    }
    connection.closed = { [unowned self] by in
      self.disconnected(by: by)
    }
  }
  public init(ip: String, port: Int) {
    connection = TCPClient(ip: ip, port: port)
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
  
  public func received(data: Data) {
    
  }
  
  public func ready() throws {
    lastActivity = .now
    if let reader = reader {
      reader.ready()
    } else {
      try appendBytes()
      while let package = try buffer.package() {
        print("tcp: constructed package \(package.count.bytesString)")
        decrypt(data: package)
        process(response: package)
      }
    }
  }
  
  
  private func appendBytes() throws {
    print("tcp: reading")
    let slice = try Data(bytes: connection.readSlice(SomeConnection2.readLength))
    print("tcp \(connection._handle): received \(reader == nil) \(slice.count) \(slice.hexString)")
    buffer.data.append(slice)
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
  
  open func send(_ data: DataWriter) throws {
    encrypt(data: data)
    data.replace(at: 0, with: Data(UInt32(data.count)))
    //    print("sending: \(data.data.hexString)")
    try connection.send(data.data)
    lastActivity = .now
  }
  open func tsend(_ data: DataWriter) {
    pthread {
      try? self.send(data)
    }
  }
  open func send(_ data: DataWriter, completion: @escaping ()->()) {
    pthread {
      do {
        try self.send(data)
        completion()
      } catch {
        
      }
    }
  }
  
  
  
  // default functions
  open func read(_ expectlen: Int, timeout: Int = -1) throws -> Data {
    return try connection.read(expectlen, timeout: timeout)
  }
  open func send(_ data: Data) throws {
    try connection.send(data)
  }
  
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
    guard let fileHandle = FileHandle(forReadingAtPath: file.location.path) else { throw NetFileError.cantOpen }
    defer { fileHandle.closeFile() }
    
    let fileSize = fileHandle.seekToEndOfFile()
    fileHandle.seek(toFileOffset: UInt64(file.completed))
    
    let chunkSize = UInt64(8.kb)
    let chunks = fileSize / chunkSize
    
    for _ in 0..<chunks {
      try autoreleasepool {
        let data = fileHandle.readData(ofLength: Int(chunkSize))
        try send(data)
      }
    }
    
    let lastChunk = fileHandle.readDataToEndOfFile()
    guard lastChunk.count > 0 else { return }
    try send(lastChunk)
  }
  
  open func request(constructor: (DataWriter) throws -> ()) throws {
    let data = sender
    try constructor(data)
    try send(data)
  }
  open func response(constructor: (DataWriter) throws -> ()) throws {
    let data = response()
    try constructor(data)
    try send(data)
  }
  
  
  open func connect(timeout: Int = 5) throws {
    try connection.connect(timeout: timeout)
  }
  
  @discardableResult
  open func disconnect() -> TCPError {
    return connection.disconnect()
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

extension SomeConnection2: Hashable {
  public var hashValue: Int { return Int(_handle) }
  public static func == (l:SomeConnection2,r:SomeConnection2) -> Bool { return l._handle == r._handle }
}

extension SomeConnection2: CustomStringConvertible {
  open var description: String { return "\(ip):\(port)" }
}
