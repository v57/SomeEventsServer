
import Foundation
//-import SomeTcpC

@_silgen_name("tcp_connect") func c_tcp_connect(_ host:UnsafePointer<Int8>,port:Int32,timeout:Int32) -> Int32
@discardableResult
@_silgen_name("tcp_close") func c_tcp_close(_ fd:Int32) -> Int32
@_silgen_name("tcp_send") func c_tcp_send(_ fd:Int32,buff:UnsafePointer<UInt8>,len:Int32) -> Int32
@_silgen_name("tcp_pull") func c_tcp_pull(_ fd:Int32,buff:UnsafePointer<UInt8>,len:Int32,timeout:Int32) -> Int32
@_silgen_name("tcp_listen") func c_tcp_listen(port:Int32)->Int32
@_silgen_name("tcp_accept") func c_tcp_accept(_ onsocketfd:Int32,ip:UnsafePointer<Int8>,port:UnsafePointer<Int32>) -> Int32

public enum TCPError: Error {
  case disconnected // close, send
}

public enum SendError: Error {
  case notSended
}

public enum ListenError: Error {
  case listenFail
}

public enum ConnectError: Error {
  case queryServerFail, connectionClosed, timeout, unknown
}

public enum ConnectionSide {
  case client, server
}

open class Socket {
  public var ip: String
  public var port: Int
  public var handle: Int32? {
    return isConnected ? _handle : nil
  }
  public var _handle: Int32
  public fileprivate(set) var isConnected: Bool = false
  
  init() {
    self.ip = ""
    self.port = 0
    self._handle = 0
  }
  public init(ip: String = "", port: Int) {
    self.ip = ip
    self.port = port
    self._handle = 0
  }
  public init(ip: String, port: Int, handle: Int32) {
    self.ip = ip
    self.port = port
    self._handle = handle
    isConnected = true
  }
}

extension Socket: Hashable {
  public static func == (l: Socket, r: Socket) -> Bool { return l._handle == r._handle }
  public var hashValue: Int { return _handle.hashValue }
}

extension Socket: CustomStringConvertible {
  public var description: String {
    return "\(ip):\(port)"
  }
}

open class TCPClient: Socket {
  public var connected: (()->())?
  public var closed: ((_ by: ConnectionSide)->())?
  
  open func connect(timeout t:Int) throws {
    let rs = c_tcp_connect(self.ip, port: Int32(self.port), timeout: Int32(t))
    if rs > 0 {
      _handle = rs
      isConnected = true
      connected?()
    } else {
      switch rs {
      case -1:
        throw ConnectError.queryServerFail
      case -2:
        throw ConnectError.connectionClosed
      case -3:
        throw ConnectError.timeout
      default:
        throw ConnectError.unknown
      }
    }
  }
  
  @discardableResult
  open func disconnect() -> TCPError {
    guard isConnected else { return TCPError.disconnected }
    let _ = c_tcp_close(_handle)
    guard isConnected else { return TCPError.disconnected }
    isConnected = false
    closed?(.client)
    return .disconnected
  }
  open func send(_ data: [UInt8]) throws {
    try checkHandle()
    let sendsize = c_tcp_send(_handle, buff: data, len: Int32(data.count))
    guard Int(sendsize) == data.count else { throw disconnect() }
    //      throw SendError.notSended }
  }
  
  open func send(_ data: Data) throws {
    try checkHandle()
    let buff = [UInt8](data)
    let sendsize: Int32 = c_tcp_send(_handle, buff: buff, len: Int32(data.count))
    guard sendsize == Int32(data.count) else { throw disconnect() }
    //      throw SendError.notSended }
  }
  open func read(_ expectlen: Int, timeout: Int = -1) throws -> Data {
    try checkHandle()
    var buff = [UInt8](repeating: 0x0, count: expectlen)
    let length = c_tcp_pull(_handle, buff: &buff, len: Int32(expectlen), timeout: Int32(timeout))
    if length <= 0 {
      try checkHandle()
      isConnected = false
      closed?(.server)
      throw TCPError.disconnected
    }
    let rs = buff[0..<Int(length)]
    return Data(bytes: rs)
  }
  open func readSlice(_ expectlen: Int, timeout: Int = -1) throws -> ArraySlice<UInt8> {
    guard handle != nil else { throw TCPError.disconnected }
    var buff = [UInt8](repeating: 0x0, count: expectlen)
    let length = c_tcp_pull(_handle, buff: &buff, len: Int32(expectlen), timeout: Int32(timeout))
    if length <= 0 {
      try checkHandle()
      isConnected = false
      closed?(.server)
      throw TCPError.disconnected
    }
    return buff[0..<Int(length)]
  }
  open func read(buffer: inout [UInt8]) throws -> ArraySlice<UInt8> {
    guard handle != nil else { throw TCPError.disconnected }
    let length = c_tcp_pull(_handle, buff: &buffer, len: Int32(buffer.count), timeout: Int32(-1))
    if length <= 0 {
      try checkHandle()
      isConnected = false
      closed?(.server)
      throw TCPError.disconnected
    }
    return buffer[0..<Int(length)]
  }
}

open class TCPServer: Socket {
  
  open func listen() throws {
    let handle = c_tcp_listen(port: Int32(self.port))
    guard handle > 0 else { throw ListenError.listenFail }
    _handle = handle
    isConnected = true
  }
  open func accept() throws -> TCPClient {
    try checkHandle()
    var buff = [Int8](repeating: 0 ,count: 16)
    var port: Int32 = 0
    let clientHandle = c_tcp_accept(_handle, ip: &buff,port: &port)
    guard clientHandle >= 0 else { throw TCPError.disconnected }
    if clientHandle < 0 {
      throw TCPError.disconnected
    }
    let ip = String(utf8String: buff) ?? "unknown"
    let tcpClient = TCPClient(ip: ip, port: Int(port), handle: clientHandle)
    return tcpClient
  }
  open func close() throws {
    try checkHandle()
    c_tcp_close(_handle)
    isConnected = false
    throw TCPError.disconnected
  }
}

extension Socket {
  func checkHandle() throws {
    guard isConnected else { throw TCPError.disconnected }
  }
}


extension Int32 {
  var canRead: Bool {
    var timeout = timeval(tv_sec: 0, tv_usec: 0)
    var readSet = fd_set()
    readSet.zero()
    readSet.set(self)
    return select(self + 1, &readSet, nil, nil, &timeout) == 1
  }
}

extension fd_set {
  mutating func zero() {
    #if arch(arm) && os(Linux)
      __fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    #elseif os(Linux)
      __fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    #else
      fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    #endif
  }
  
  mutating func set(_ fd: Int32) {
    #if arch(arm) && os(Linux)
      let intOffset = Int(fd / 32)
      let bitOffset: Int = Int(fd % 32)
      let mask: Int = 1 << bitOffset
      switch intOffset {
      case 0: __fds_bits.0 = __fds_bits.0 | mask
      case 1: __fds_bits.1 = __fds_bits.1 | mask
      case 2: __fds_bits.2 = __fds_bits.2 | mask
      case 3: __fds_bits.3 = __fds_bits.3 | mask
      case 4: __fds_bits.4 = __fds_bits.4 | mask
      case 5: __fds_bits.5 = __fds_bits.5 | mask
      case 6: __fds_bits.6 = __fds_bits.6 | mask
      case 7: __fds_bits.7 = __fds_bits.7 | mask
      case 8: __fds_bits.8 = __fds_bits.8 | mask
      case 9: __fds_bits.9 = __fds_bits.9 | mask
      case 10: __fds_bits.10 = __fds_bits.10 | mask
      case 11: __fds_bits.11 = __fds_bits.11 | mask
      case 12: __fds_bits.12 = __fds_bits.12 | mask
      case 13: __fds_bits.13 = __fds_bits.13 | mask
      case 14: __fds_bits.14 = __fds_bits.14 | mask
      case 15: __fds_bits.15 = __fds_bits.15 | mask
      case 16: __fds_bits.16 = __fds_bits.16 | mask
      case 17: __fds_bits.17 = __fds_bits.17 | mask
      case 18: __fds_bits.18 = __fds_bits.18 | mask
      case 19: __fds_bits.19 = __fds_bits.19 | mask
      case 20: __fds_bits.20 = __fds_bits.20 | mask
      case 21: __fds_bits.21 = __fds_bits.21 | mask
      case 22: __fds_bits.22 = __fds_bits.22 | mask
      case 23: __fds_bits.23 = __fds_bits.23 | mask
      case 24: __fds_bits.24 = __fds_bits.24 | mask
      case 25: __fds_bits.25 = __fds_bits.25 | mask
      case 26: __fds_bits.26 = __fds_bits.26 | mask
      case 27: __fds_bits.27 = __fds_bits.27 | mask
      case 28: __fds_bits.28 = __fds_bits.28 | mask
      case 29: __fds_bits.29 = __fds_bits.29 | mask
      case 30: __fds_bits.20 = __fds_bits.30 | mask
      case 31: __fds_bits.31 = __fds_bits.31 | mask
      default: break
      }
    #elseif os(Linux)
      let intOffset = Int(fd / 16)
      let bitOffset: Int = Int(fd % 16)
      let mask: Int = 1 << bitOffset
      switch intOffset {
      case 0: __fds_bits.0 = __fds_bits.0 | mask
      case 1: __fds_bits.1 = __fds_bits.1 | mask
      case 2: __fds_bits.2 = __fds_bits.2 | mask
      case 3: __fds_bits.3 = __fds_bits.3 | mask
      case 4: __fds_bits.4 = __fds_bits.4 | mask
      case 5: __fds_bits.5 = __fds_bits.5 | mask
      case 6: __fds_bits.6 = __fds_bits.6 | mask
      case 7: __fds_bits.7 = __fds_bits.7 | mask
      case 8: __fds_bits.8 = __fds_bits.8 | mask
      case 9: __fds_bits.9 = __fds_bits.9 | mask
      case 10: __fds_bits.10 = __fds_bits.10 | mask
      case 11: __fds_bits.11 = __fds_bits.11 | mask
      case 12: __fds_bits.12 = __fds_bits.12 | mask
      case 13: __fds_bits.13 = __fds_bits.13 | mask
      case 14: __fds_bits.14 = __fds_bits.14 | mask
      case 15: __fds_bits.15 = __fds_bits.15 | mask
      default: break
      }
    #else
      let intOffset = Int(fd / 32)
      let bitOffset = fd % 32
      let mask = Int32(1 << bitOffset)
      switch intOffset {
      case 0: fds_bits.0 = fds_bits.0 | mask
      case 1: fds_bits.1 = fds_bits.1 | mask
      case 2: fds_bits.2 = fds_bits.2 | mask
      case 3: fds_bits.3 = fds_bits.3 | mask
      case 4: fds_bits.4 = fds_bits.4 | mask
      case 5: fds_bits.5 = fds_bits.5 | mask
      case 6: fds_bits.6 = fds_bits.6 | mask
      case 7: fds_bits.7 = fds_bits.7 | mask
      case 8: fds_bits.8 = fds_bits.8 | mask
      case 9: fds_bits.9 = fds_bits.9 | mask
      case 10: fds_bits.10 = fds_bits.10 | mask
      case 11: fds_bits.11 = fds_bits.11 | mask
      case 12: fds_bits.12 = fds_bits.12 | mask
      case 13: fds_bits.13 = fds_bits.13 | mask
      case 14: fds_bits.14 = fds_bits.14 | mask
      case 15: fds_bits.15 = fds_bits.15 | mask
      case 16: fds_bits.16 = fds_bits.16 | mask
      case 17: fds_bits.17 = fds_bits.17 | mask
      case 18: fds_bits.18 = fds_bits.18 | mask
      case 19: fds_bits.19 = fds_bits.19 | mask
      case 20: fds_bits.20 = fds_bits.20 | mask
      case 21: fds_bits.21 = fds_bits.21 | mask
      case 22: fds_bits.22 = fds_bits.22 | mask
      case 23: fds_bits.23 = fds_bits.23 | mask
      case 24: fds_bits.24 = fds_bits.24 | mask
      case 25: fds_bits.25 = fds_bits.25 | mask
      case 26: fds_bits.26 = fds_bits.26 | mask
      case 27: fds_bits.27 = fds_bits.27 | mask
      case 28: fds_bits.28 = fds_bits.28 | mask
      case 29: fds_bits.29 = fds_bits.29 | mask
      case 30: fds_bits.30 = fds_bits.30 | mask
      case 31: fds_bits.31 = fds_bits.31 | mask
      default: break
      }
    #endif
  }
  
  mutating func clear(_ fd: Int32) {
    #if arch(arm) && os(Linux)
      let intOffset = Int(fd / 32)
      let bitOffset: Int = Int(fd % 32)
      let mask: Int = ~(1 << bitOffset)
      switch intOffset {
      case 0: __fds_bits.0 = __fds_bits.0 & mask
      case 1: __fds_bits.1 = __fds_bits.1 & mask
      case 2: __fds_bits.2 = __fds_bits.2 & mask
      case 3: __fds_bits.3 = __fds_bits.3 & mask
      case 4: __fds_bits.4 = __fds_bits.4 & mask
      case 5: __fds_bits.5 = __fds_bits.5 & mask
      case 6: __fds_bits.6 = __fds_bits.6 & mask
      case 7: __fds_bits.7 = __fds_bits.7 & mask
      case 8: __fds_bits.8 = __fds_bits.8 & mask
      case 9: __fds_bits.9 = __fds_bits.9 & mask
      case 10: __fds_bits.10 = __fds_bits.10 & mask
      case 11: __fds_bits.11 = __fds_bits.11 & mask
      case 12: __fds_bits.12 = __fds_bits.12 & mask
      case 13: __fds_bits.13 = __fds_bits.13 & mask
      case 14: __fds_bits.14 = __fds_bits.14 & mask
      case 15: __fds_bits.15 = __fds_bits.15 & mask
      case 16: __fds_bits.16 = __fds_bits.16 & mask
      case 17: __fds_bits.17 = __fds_bits.17 & mask
      case 18: __fds_bits.18 = __fds_bits.18 & mask
      case 19: __fds_bits.19 = __fds_bits.19 & mask
      case 20: __fds_bits.20 = __fds_bits.20 & mask
      case 21: __fds_bits.21 = __fds_bits.21 & mask
      case 22: __fds_bits.22 = __fds_bits.22 & mask
      case 23: __fds_bits.23 = __fds_bits.23 & mask
      case 24: __fds_bits.24 = __fds_bits.24 & mask
      case 25: __fds_bits.25 = __fds_bits.25 & mask
      case 26: __fds_bits.26 = __fds_bits.26 & mask
      case 27: __fds_bits.27 = __fds_bits.27 & mask
      case 28: __fds_bits.28 = __fds_bits.28 & mask
      case 29: __fds_bits.29 = __fds_bits.29 & mask
      case 30: __fds_bits.20 = __fds_bits.30 & mask
      case 31: __fds_bits.31 = __fds_bits.31 & mask
      default: break
      }
    #elseif os(Linux)
      let intOffset = Int(fd / 16)
      let bitOffset: Int = Int(fd % 16)
      let mask: Int = ~(1 << bitOffset)
      switch intOffset {
      case 0: __fds_bits.0 = __fds_bits.0 & mask
      case 1: __fds_bits.1 = __fds_bits.1 & mask
      case 2: __fds_bits.2 = __fds_bits.2 & mask
      case 3: __fds_bits.3 = __fds_bits.3 & mask
      case 4: __fds_bits.4 = __fds_bits.4 & mask
      case 5: __fds_bits.5 = __fds_bits.5 & mask
      case 6: __fds_bits.6 = __fds_bits.6 & mask
      case 7: __fds_bits.7 = __fds_bits.7 & mask
      case 8: __fds_bits.8 = __fds_bits.8 & mask
      case 9: __fds_bits.9 = __fds_bits.9 & mask
      case 10: __fds_bits.10 = __fds_bits.10 & mask
      case 11: __fds_bits.11 = __fds_bits.11 & mask
      case 12: __fds_bits.12 = __fds_bits.12 & mask
      case 13: __fds_bits.13 = __fds_bits.13 & mask
      case 14: __fds_bits.14 = __fds_bits.14 & mask
      case 15: __fds_bits.15 = __fds_bits.15 & mask
      default: break
      }
    #else
    let intOffset = Int(fd / 32)
    let bitOffset = fd % 32
    let mask = Int32(~(1 << bitOffset))
    switch intOffset {
    case 0: fds_bits.0 = fds_bits.0 & mask
    case 1: fds_bits.1 = fds_bits.1 & mask
    case 2: fds_bits.2 = fds_bits.2 & mask
    case 3: fds_bits.3 = fds_bits.3 & mask
    case 4: fds_bits.4 = fds_bits.4 & mask
    case 5: fds_bits.5 = fds_bits.5 & mask
    case 6: fds_bits.6 = fds_bits.6 & mask
    case 7: fds_bits.7 = fds_bits.7 & mask
    case 8: fds_bits.8 = fds_bits.8 & mask
    case 9: fds_bits.9 = fds_bits.9 & mask
    case 10: fds_bits.10 = fds_bits.10 & mask
    case 11: fds_bits.11 = fds_bits.11 & mask
    case 12: fds_bits.12 = fds_bits.12 & mask
    case 13: fds_bits.13 = fds_bits.13 & mask
    case 14: fds_bits.14 = fds_bits.14 & mask
    case 15: fds_bits.15 = fds_bits.15 & mask
    case 16: fds_bits.16 = fds_bits.16 & mask
    case 17: fds_bits.17 = fds_bits.17 & mask
    case 18: fds_bits.18 = fds_bits.18 & mask
    case 19: fds_bits.19 = fds_bits.19 & mask
    case 20: fds_bits.20 = fds_bits.20 & mask
    case 21: fds_bits.21 = fds_bits.21 & mask
    case 22: fds_bits.22 = fds_bits.22 & mask
    case 23: fds_bits.23 = fds_bits.23 & mask
    case 24: fds_bits.24 = fds_bits.24 & mask
    case 25: fds_bits.25 = fds_bits.25 & mask
    case 26: fds_bits.26 = fds_bits.26 & mask
    case 27: fds_bits.27 = fds_bits.27 & mask
    case 28: fds_bits.28 = fds_bits.28 & mask
    case 29: fds_bits.29 = fds_bits.29 & mask
    case 30: fds_bits.30 = fds_bits.30 & mask
    case 31: fds_bits.31 = fds_bits.31 & mask
    default: break
    }
    #endif
  }
  
  mutating func isSet(_ fd: Int32) -> Bool {
    #if arch(arm) && os(Linux)
      let intOffset = Int(fd / 32)
      let bitOffset = Int(fd % 32)
      let mask: Int = 1 << bitOffset
      switch intOffset {
      case 0: return __fds_bits.0 & mask != 0
      case 1: return __fds_bits.1 & mask != 0
      case 2: return __fds_bits.2 & mask != 0
      case 3: return __fds_bits.3 & mask != 0
      case 4: return __fds_bits.4 & mask != 0
      case 5: return __fds_bits.5 & mask != 0
      case 6: return __fds_bits.6 & mask != 0
      case 7: return __fds_bits.7 & mask != 0
      case 8: return __fds_bits.8 & mask != 0
      case 9: return __fds_bits.9 & mask != 0
      case 10: return __fds_bits.10 & mask != 0
      case 11: return __fds_bits.11 & mask != 0
      case 12: return __fds_bits.12 & mask != 0
      case 13: return __fds_bits.13 & mask != 0
      case 14: return __fds_bits.14 & mask != 0
      case 15: return __fds_bits.15 & mask != 0
      case 16: return __fds_bits.16 & mask != 0
      case 17: return __fds_bits.17 & mask != 0
      case 18: return __fds_bits.18 & mask != 0
      case 19: return __fds_bits.19 & mask != 0
      case 20: return __fds_bits.20 & mask != 0
      case 21: return __fds_bits.21 & mask != 0
      case 22: return __fds_bits.22 & mask != 0
      case 23: return __fds_bits.23 & mask != 0
      case 24: return __fds_bits.24 & mask != 0
      case 25: return __fds_bits.25 & mask != 0
      case 26: return __fds_bits.26 & mask != 0
      case 27: return __fds_bits.27 & mask != 0
      case 28: return __fds_bits.28 & mask != 0
      case 29: return __fds_bits.29 & mask != 0
      case 30: return __fds_bits.30 & mask != 0
      case 31: return __fds_bits.31 & mask != 0
      default: return false
      }
    #elseif os(Linux)
      let intOffset = Int(fd / 16)
      let bitOffset = Int(fd % 16)
      let mask: Int = 1 << bitOffset
      switch intOffset {
      case 0: return __fds_bits.0 & mask != 0
      case 1: return __fds_bits.1 & mask != 0
      case 2: return __fds_bits.2 & mask != 0
      case 3: return __fds_bits.3 & mask != 0
      case 4: return __fds_bits.4 & mask != 0
      case 5: return __fds_bits.5 & mask != 0
      case 6: return __fds_bits.6 & mask != 0
      case 7: return __fds_bits.7 & mask != 0
      case 8: return __fds_bits.8 & mask != 0
      case 9: return __fds_bits.9 & mask != 0
      case 10: return __fds_bits.10 & mask != 0
      case 11: return __fds_bits.11 & mask != 0
      case 12: return __fds_bits.12 & mask != 0
      case 13: return __fds_bits.13 & mask != 0
      case 14: return __fds_bits.14 & mask != 0
      case 15: return __fds_bits.15 & mask != 0
      default: return false
      }
    #else
    let intOffset = Int(fd / 32)
    let bitOffset = fd % 32
    let mask = Int32(1 << bitOffset)
    switch intOffset {
    case 0: return fds_bits.0 & mask != 0
    case 1: return fds_bits.1 & mask != 0
    case 2: return fds_bits.2 & mask != 0
    case 3: return fds_bits.3 & mask != 0
    case 4: return fds_bits.4 & mask != 0
    case 5: return fds_bits.5 & mask != 0
    case 6: return fds_bits.6 & mask != 0
    case 7: return fds_bits.7 & mask != 0
    case 8: return fds_bits.8 & mask != 0
    case 9: return fds_bits.9 & mask != 0
    case 10: return fds_bits.10 & mask != 0
    case 11: return fds_bits.11 & mask != 0
    case 12: return fds_bits.12 & mask != 0
    case 13: return fds_bits.13 & mask != 0
    case 14: return fds_bits.14 & mask != 0
    case 15: return fds_bits.15 & mask != 0
    case 16: return fds_bits.16 & mask != 0
    case 17: return fds_bits.17 & mask != 0
    case 18: return fds_bits.18 & mask != 0
    case 19: return fds_bits.19 & mask != 0
    case 20: return fds_bits.20 & mask != 0
    case 21: return fds_bits.21 & mask != 0
    case 22: return fds_bits.22 & mask != 0
    case 23: return fds_bits.23 & mask != 0
    case 24: return fds_bits.24 & mask != 0
    case 25: return fds_bits.25 & mask != 0
    case 26: return fds_bits.26 & mask != 0
    case 27: return fds_bits.27 & mask != 0
    case 28: return fds_bits.28 & mask != 0
    case 29: return fds_bits.29 & mask != 0
    case 30: return fds_bits.30 & mask != 0
    case 31: return fds_bits.31 & mask != 0
    default: return false
    }
    #endif
  }
}
