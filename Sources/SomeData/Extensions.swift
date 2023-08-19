
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import SomeFunctions

public enum DataError: Error {
  case corrupted
}
public var corrupted: Error = DataError.corrupted

public func unraw<T>(_ raw: ArraySlice<UInt8>) -> T {
  return raw.withUnsafeBufferPointer {
    $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1, { pointer in
      return pointer.pointee
    })
  }
}
public func unraw<T>(_ raw: [UInt8]) -> T {
  return raw.withUnsafeBufferPointer {
    $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1, { pointer in
      return pointer.pointee
    })
  }
}
public func unraw<T>(_ raw: UnsafeRawPointer) -> T {
  return raw.assumingMemoryBound(to: T.self).pointee
}
public func unraw<T>(_ raw: UnsafePointer<T>) -> T {
  return raw.pointee
}
public func raw(_ pointer: UnsafeRawPointer) -> UnsafeRawPointer {
  return pointer
}


//public protocol DataRepresentable {
//  init(data: DataReader) throws
//  func save(data: DataWriter)
//}
//
//public protocol DataLoadable: class {
//  func load(data: DataReader)
//  func save(data: DataWriter)
//}

public protocol UInt8Enum {
  var rawValue: UInt8 { get }
}

extension Data {
  public init?(path: String) {
    do {
      self = try Data(contentsOf: URL(fileURLWithPath: path))
    } catch {
      return nil
    }
  }
  public func write(to path: String) {
    do {
      try write(to: URL(fileURLWithPath: path))
    } catch {}
  }
  public var bytes: [UInt8] {
    return withUnsafeBytes {
      [UInt8](UnsafeBufferPointer(start: $0, count: self.count))
    }
  }
  public mutating func append(raw: UnsafeRawPointer, length: Int) {
    let pointer = raw.assumingMemoryBound(to: UInt8.self)
    append(pointer, count: length)
  }
  public func copy() -> Data {
    return withUnsafeBytes {
      Data(bytes: $0, count: count)
    }
  }
}

extension Sequence where Iterator.Element == UInt8 {
  public var data: Data {
    if let data = self as? Data {
      return data
    } else if let array = self as? Array<UInt8> {
      return Data(bytes: array)
    } else if let slice = self as? ArraySlice<UInt8> {
      return Data(bytes: slice)
    } else {
      return Data(bytes: Array(self))
    }
  }
  public var hexString: String {
    var string = ""
    for (index, i) in self.enumerated() {
      string += i.hex
      if index % 4 == 3 {
        string += " "
      }
    }
    return string
  }
  public var hexString2: String {
    var string = ""
    for i in self {
      string += i.hex
    }
    return string
  }
  public var string: String! {
    return String(bytes: self, encoding: .utf8)
  }
}

extension UInt8 {
  public var hex: String {
    if self < 0x10 {
      return "0" + String(self, radix: 16)
    } else {
      return String(self, radix: 16)
    }
  }
}

extension String {
  public var length: Int {
    return utf8.count
  }
}

extension UInt64 {
  public var bytesString: String {
    if self < UInt64(1).kb {
      return "\(self) bytes"
    } else if self < UInt64(1).mb {
      return "\(self.toKB) KB"
    } else {
      return "\(self.toMB) MB"
    }
  }
  public var kb: UInt64 {
    return self * 1024
  }
  public var mb: UInt64 {
    return self * 1048576
  }
  public var toKB: UInt64 {
    return self / 1024
  }
  public var toMB: UInt64 {
    return self / 1048576
  }
  
  public var hex: String {
    var a = self
    let pointer = raw(&a).assumingMemoryBound(to: UInt8.self)
    var data = Data()
    data.append(pointer, count: 8)
    return data.hexString2
  }
}

extension Int64 {
  public var bytesString: String {
    if self < Int64(1).kb {
      return "\(self) bytes"
    } else if self < Int64(1).mb {
      return "\(self.toKB) KB"
    } else {
      return "\(self.toMB) MB"
    }
  }
  public var kb: Int64 {
    return self * 1024
  }
  public var mb: Int64 {
    return self * 1048576
  }
  public var gb: Int64 {
    return self * 1052872704
  }
  public var toKB: Int64 {
    return self / 1024
  }
  public var toMB: Int64 {
    return self / 1048576
  }
}

extension FileURL {
  public var reader: DataReader? {
    return DataReader(url: self)
  }
  public func write(data: DataWriter) {
    try? data.write(to: self)
  }
  public func write(data: Data) {
    try? data.write(to: self)
  }
}

extension Int {
  public var bytesString: String {
    if self < 1.kb {
      return "\(self) bytes"
    } else if self < 1.mb {
      return "\(self.toKB) KB"
    } else {
      return "\(self.toMB) MB"
    }
  }
  public var bytesStringShort: String {
    if self < 1.kb {
      return "\(self)b"
    } else if self < 1.mb {
      return "\(self.toKB)kb"
    } else {
      return "\(self.toMB)mb"
    }
  }
  public var kb: Int {
    return self * 1024
  }
  public var mb: Int {
    return self * 1048576
  }
  public var gb: Int {
    return self * 1052872704
  }
  public var toKB: Int {
    return self / 1024
  }
  public var toMB: Int {
    return self / 1048576
  }
}

