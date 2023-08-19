
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

/*
extension SomeSettings {
  public static var dataWriterProtection = false
}

open class DataWriter {
  open var data: Data
  open var base64: String { return data.base64EncodedString() }
  public init(_ data: Data) {
    self.data = data
  }
  public init() {
    self.data = Data()
  }
  public func write(to url: FileURL) throws {
    if SomeSettings.dataWriterProtection {
      try data.write(to: url.url, options: .completeFileProtection)
    } else {
      try data.write(to: url)
    }
  }
  
  public var count: Int {
    return data.count
  }
  public var isEmpty: Bool {
    return data.isEmpty
  }
}
*/
/*
extension DataWriter {
  public func append(_ bytes: UnsafeRawPointer, length: Int) {
    let pointer = bytes.assumingMemoryBound(to: UInt8.self)
    data.append(pointer, count: length)
  }
  public func replace(_ bytes: UnsafeRawPointer, length: Int, at index: Int) {
    let pointer = bytes.assumingMemoryBound(to: UInt8.self)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    data.replaceSubrange(index..<index+length, with: buffer)
  }
  
  public func replace<T>(at index: Int, with value: T) {
    var value = value
    replace(&value, length: MemoryLayout<T>.size, at: index)
  }
  public func replace<T>(at index: Int, with value: [T]) {
    replace(at: index, with: Int32(value.count))
    var value = value
    replace(&value, length: MemoryLayout<T>.size * value.count, at: index)
  }
  public func replace(at index: Int, withBytes bytes: [UInt8]) {
    var bytes = bytes
    replace(&bytes, length: bytes.count, at: index)
  }
  
  #if !__LP64__
  public func append(_ value: Int) {
    append(Int64(value))
  }
  public func append(_ value: [Int]) {
    append(value.map { Int64($0) })
  }
  public func append(_ value: Set<Int>) {
    append(value.map { Int64($0) })
  }
  #endif
  
  public func append(_ value: Bool) {
    append(UInt8(value ? 1 : 0))
  }
  
  // MARK:- Data
  public func append(_ value: Data) {
    append(UInt32(value.count))
    data.append(value)
  }
  public func append(_ value: DataWriter) {
    append(UInt32(value.data.count))
    data.append(value.data)
  }
  
  public func append(_ value: DataReader) {
    append(value.bytes)
  }
  
  // MARK:- <T>
  public func append<T>(_ value: T) {
    var value = value
    append(&value, length: MemoryLayout<T>.size)
  }
  public func append<T>(_ value: [T]) {
    append(count32: value.count)
    var value = value
    append(&value, length: MemoryLayout<T>.size * value.count)
  }
  
  public func append<T>(_ value: Set<T>) {
    append(count32: value.count)
    var value = Array(value)
    append(&value, length: MemoryLayout<T>.size * value.count)
  }
  
  
  // MARK:- DataRepresentable
  public func append(_ value: DataRepresentable) {
    value.save(data: self)
  }
  public func append(_ value: [DataRepresentable]) {
    append(count32: value.count)
    for v in value {
      v.save(data: self)
    }
  }
  
  public func append(_ value: DataLoadable) {
    value.save(data: self)
  }
  public func append(_ value: [DataLoadable]) {
    append(count32: value.count)
    for v in value {
      v.save(data: self)
    }
  }
  
  
  public func append(binary: DataRepresentable) {
    binary.save(data: self)
  }
  public func append(binary: [DataRepresentable]) {
    append(count32: binary.count)
    for v in binary {
      v.save(data: self)
    }
  }
  
  public func append(binary: DataLoadable) {
    binary.save(data: self)
  }
  public func append(binary: [DataLoadable]) {
    append(count32: binary.count)
    for v in binary {
      v.save(data: self)
    }
  }
  @available (*,unavailable)
  public func append<T>(_ value: T)
    where T: RawRepresentable {
      (value.rawValue as! Packable).write(to: self)
  }
  public func append<T>(enum value: T)
    where T : RawRepresentable {
      (value.rawValue as! Packable).write(to: self)
  }
  
  
  // MARK:- String
  public func append(_ value: String) {
    var bytes = Array<UInt8>(value.utf8)
    append(bytes.count)
    append(&bytes, length: bytes.count)
  }
  public func append(_ value: [String]) {
    append(count32: value.count)
    for string in value {
      append(string)
    }
  }
  public func append(_ value: Set<String>) {
    append(count32: value.count)
    for string in value {
      append(string)
    }
  }
  public func append(string8 value: String) {
    var bytes = Array<UInt8>(value.utf8)
    bytes.limit(0xff)
    append(count8: bytes.count)
    append(&bytes, length: bytes.count)
  }
  public func append(string8 value: [String]) {
    append(count32: value.count)
    for string in value {
      append(string)
    }
  }
  public func append(string8 value: Set<String>) {
    append(count32: value.count)
    for string in value {
      append(string)
    }
  }
  public func append(string32 value: String) {
    var bytes = Array<UInt8>(value.utf8)
    append(count32: bytes.count)
    append(&bytes, length: bytes.count)
  }
  public func append(string32 value: [String]) {
    append(count32: value.count)
    for string in value {
      append( string)
    }
  }
  public func append(string32 value: Set<String>) {
    append(count32: value.count)
    for string in value {
      append( string)
    }
  }
  
  // MARK:- Count
  public func append(count64 value: Int, max: Int = .max) {
    append(UInt64(value))
  }
  public func append(count32 value: Int, max: Int = .max) {
    append(UInt32(value))
  }
  public func append(count16 value: Int) {
    append(UInt16(value))
  }
  public func append(count8 value: Int) {
    append(UInt8(value))
  }
}
*/
