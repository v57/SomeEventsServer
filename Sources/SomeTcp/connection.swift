//
//  connection.swift
//  iostcp
//
//  Created by Дмитрий Козлов on 11/2/16.
//  Copyright © 2016 Дмитрий Козлов. All rights reserved.
//

import Foundation
import Dispatch
import SomeFunctions
import SomeData


public extension DataWriter {
  public func spam() {
    replace(at: 0, with: Data(UInt32(count)))
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



open class NetFile: ProgressProtocol {
  public enum ConnectionType {
    case download, upload
  }
  public var total: Int64 = 0
  public var completed: Int64 = 0
  public var isPaused: Bool = false
  public var isCancelled: Bool = false
  public var isCompleted: Bool { return total != 0 && total == completed }
  public var location: FileURL
  public var tempLocation: FileURL
  
  public init(at url: FileURL) {
    location = url
    tempLocation = url.temp
  }
  
  public func prepare(for type: ConnectionType) {
    if type == .upload {
      total = location.fileSize
      if completed >= total {
        completed = 0
      }
    } else {
      completed = tempLocation.fileSize
      if completed >= total {
        completed = 0
      }
    }
  }
}

public func spammer() -> DataWriter {
  let writer = DataWriter()
  writer.data.append(UInt32(0))
  return writer
}

public enum NetFileError: Error {
  case cantOpen, wrongSize
}

open class SomeConnection {
  public static var readLength = 1024
  public static var printFileProgress = false
  public var data = DataReader()
  public var isConnected: Bool { return connection.isConnected }
  
  private var _data = DataReader()
  private let semaphore = DispatchSemaphore(value: 0)
  private var connection: TCPClient
  private var responses = [DataReader]()
  
  func set(password: UInt64) {
    sendPassword = password
    readPassword = password
  }
  private var sendPassword: UInt64 = 0
  private var readPassword: UInt64 = 0
  private func encrypt(data: DataWriter) {
    guard sendPassword != 0 else { return }
    data.encrypt(password: sendPassword)
  }
  private func decrypt(data: DataReader) {
    guard readPassword != 0 else { return }
    data.decrypt(password: sendPassword)
  }
  private func encrypt(data: inout Data, offset: Int) {
    guard sendPassword != 0 else { return }
    data.encrypt(password: sendPassword, offset: offset)
  }
  private func decrypt(data: inout Data, offset: Int) {
    guard readPassword != 0 else { return }
    data.decrypt(password: sendPassword, offset: offset)
  }
  
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
  open func listen() throws {
    try connection.checkHandle()
    while true {
      if let package = try _data.package() {
        decrypt(data: package)
        process(response: package)
      } else {
        try appendBytes()
        lastActivity = .now
      }
    }
  }
  
  private func process(response: DataReader) {
    guard response.has(unusedBytes: 1) else { return }
    let type = try! response.uint8()
    if type == 0 {
      responses.append(response)
      semaphore.signal()
    } else {
      try? notification(type: type, data: response)
    }
  }
  
  open func send(_ data: DataWriter) throws {
    encrypt(data: data)
    data.pack()
    print("sending: \(data.data.hexString)")
    try connection.send(data.data)
    lastActivity = .now
  }
  
  /// вызывается в сервер треде
  open func read() throws {
    if responses.count > 0 {
      data = responses.removeFirst()
    } else {
      try connection.checkHandle()
      semaphore.wait()
      try connection.checkHandle()
      guard !responses.isEmpty else { throw TCPError.disconnected }
      data = responses.removeFirst()
      try connection.checkHandle()
    }
  }
  
  /// вызывается в треде уведомлений или перед listen()
  open func nread() throws {
    while true {
      if let package = try _data.package() {
        decrypt(data: package)
        let type = try! package.uint8()
        if type == 0 {
          data = package
          return
        } else {
          try? notification(type: type, data: package)
        }
        return
      } else {
        try appendBytes()
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
  
  open func read(_ file: NetFile) throws {
    file.tempLocation.create()
    let fileHandle = try FileHandle(forWritingTo: file.tempLocation.url)
    fileHandle.seek(toFileOffset: UInt64(file.completed))
    
    let firstPackage = _data.data[_data.position..<_data.count]
    
    // делаем, чтобы file.isCompleted был false, пока файл не переместится
    file.completed -= 1
    
    if firstPackage.count > 0 {
      fileHandle.write(firstPackage)
      file.completed += Int64(firstPackage.count)
    }
    
    while file.completed + 1 < file.total {
      if file.isCancelled {
        throw disconnect()
      }
      let data = try read(100.kb)
      fileHandle.write(data)
      file.completed += Int64(data.count)
      print("\(file.completed + 1)/\(file.total)")
    }
    file.tempLocation.move(to: file.location)
    
    file.completed += 1
  }
  
  open func send(_ file: NetFile) throws {
    guard let fileHandle = FileHandle(forReadingAtPath: file.location.path) else { throw NetFileError.cantOpen }
    defer { fileHandle.closeFile() }
    
    let fileSize = fileHandle.seekToEndOfFile()
    fileHandle.seek(toFileOffset: UInt64(file.completed))
    
    let chunkSize = UInt64(100.kb)
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
  open func read(constructor: (DataReader) throws -> ()) throws {
    try read()
    try constructor(data)
  }
  
  private func appendBytes() throws {
    print("reading")
    let slice = try connection.readSlice(SomeConnection.readLength)
    print("received: \(slice.hexString)")
    _data.data.append(contentsOf: slice)
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
    semaphore.signal()
  }
  
  open func notification(type: UInt8, data: DataReader) throws {
    
  }
}

extension SomeConnection: Hashable {
  public var hashValue: Int { return Int(_handle) }
  public static func == (l:SomeConnection,r:SomeConnection) -> Bool { return l._handle == r._handle }
}

extension SomeConnection: CustomStringConvertible {
  open var description: String { return "\(ip):\(port)" }
}
