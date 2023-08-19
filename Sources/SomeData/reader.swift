
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

public enum ReaderError: Error {
  case out, corrupted
}

open class DataReader {
  public var bytes: [UInt8]
  public var position = 0
  public init() {
    self.bytes = []
  }
  public init?(base64: String) {
    guard let data = Data(base64Encoded: base64) else { return nil }
    self.bytes = data.bytes
  }
  public init(_ data: Data) {
    self.bytes = data.bytes
  }
  public init(_ bytes: [UInt8]) {
    self.bytes = bytes
  }
  public required init(slice bytes: ArraySlice<UInt8>) {
    self.bytes = Array(bytes)
  }
  public init?(url: FileURL) {
    if let data = Data(contentsOf: url) {
      self.bytes = data.bytes
    } else {
      return nil
    }
  }
  
  public var count: Int { return bytes.count }
  public var isEmpty: Bool { return bytes.isEmpty }
  
  public func fromBytes<T>(_ value: ArraySlice<UInt8>, _ type: T.Type, capacity: Int = 1) -> T {
    return value.withUnsafeBufferPointer { value in
      
      $0.baseAddress!.withMemoryRebound(to: type, capacity: capacity) {
        $0.pointee
      }
    }
  }
  
}

/*
extension DataReader {
  
  public func next<T: DataRepresentable>() throws -> T {
    return try T.init(data: self)
  }
  
  public class func check(count: Int) throws {
    if count > 1000000 || count < 0 {
      throw corrupted
    }
  }
  
  public func nextArray<T: DataRepresentable>() throws -> [T] {
    let count = try count32()
    var array = [T]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(next())
    }
    return array
  }
  public func nextSet<T: DataRepresentable>() throws -> Set<T> {
    let count = try count32()
    var array = [T]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(next())
    }
    return Set(array)
  }
  
  public func nextArray<T>() throws -> [T] {
    let count = try count32()
    var array = [T]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(next())
    }
    return array
  }
  public func nextSet<T>() throws -> Set<T> {
    let count = try count32()
    var set = Set<T>()
    for _ in 0..<count {
      try set.insert(next())
    }
    return set
  }
  public func next<T>() throws -> Set<T> {
    let count = try count32()
    var set = Set<T>()
    for _ in 0..<count {
      try set.insert(next())
    }
    return set
  }
  public func next<T>() throws -> [T] {
    let count = try count32()
    var array = [T]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(next())
    }
    return array
  }
  public func next<T>() throws -> T {
    let size = MemoryLayout<T>.size
    let start = position
    let end = position + size
    guard end <= bytes.count else { throw ReaderError.out }
    position = end
    let slice = bytes[start..<end]
    return fromBytes(slice, T.self)
  }
  #if !__LP64__
  public func next() throws -> Int {
    let value: Int64 = try next()
    return Int(value)
  }
  public func nextArray() throws -> [Int] {
    let value: [Int64] = try nextArray()
    return value.map { Int($0) }
  }
  public func nextSet() throws -> Set<Int> {
    let value: [Int] = try nextArray()
    return Set(value)
  }
  #endif
  public func next() throws -> String {
    let count = try count16()
    return try string(count: count)
  }
  public func next() throws -> [String] {
    let count = try count32()
    var array = [String]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(string())
    }
    return array
  }
  public func next() throws -> Set<String> {
    let array: [String] = try next()
    return Set(array)
  }
  public func reader() throws -> DataReader {
    let length = try count32()
    let start = position
    let end = position + length
    guard end <= bytes.count else { throw ReaderError.out }
    position = end
    
    let slice = bytes[start..<end]
    let reader = DataReader(slice)
    return reader
  }
  public func data() throws -> Data {
    let length = try count32()
    let start = position
    let end = position + length
    guard end <= bytes.count else { throw ReaderError.out }
    position = end
    let slice = bytes[start..<end]
    let data = Data(bytes: slice)
    return data
  }
  
  public func float() throws -> Float {
    return try next()
  }
  public func double() throws -> Double {
    return try next()
  }
  
  public func bool() throws -> Bool {
    let uint: UInt8 = try next()
    if uint == 0 {
      return false
    } else if uint == 1 {
      return true
    } else {
      throw corrupted
    }
  }
  public func uint() throws -> UInt {
    return try next()
  }
  public func uint64() throws -> UInt64 {
    return try next()
  }
  public func uint32() throws -> UInt32 {
    return try next()
  }
  public func uint16() throws -> UInt16 {
    return try next()
  }
  public func uint8() throws -> UInt8 {
    return try next()
  }
  public func int() throws -> Int {
    return try next()
  }
  public func int64() throws -> Int64 {
    return try next()
  }
  public func int32() throws -> Int32 {
    return try next()
  }
  public func int16() throws -> Int16 {
    return try next()
  }
  public func int8() throws -> Int8 {
    return try next()
  }
  public func string() throws -> String {
    return try string(count: count16())
  }
  public func string() throws -> String {
    return try string(count: count8())
  }
  public func string16() throws -> String {
    return try string(count: count16())
  }
  public func string32() throws -> String {
    return try string(count: count32(max: 100000))
  }
  private func string(count: Int) throws -> String {
    let end = position + count
    guard end <= bytes.count else { throw ReaderError.out }
    let slice = bytes[position..<end]
    guard let string = slice.string else { throw corrupted }
    position = end
    return string
  }
  
  
  public func uintArray() throws -> [UInt] {
    return try nextArray()
  }
  public func uint64Array() throws -> [UInt64] {
    return try nextArray()
  }
  public func uint32Array() throws -> [UInt32] {
    return try nextArray()
  }
  public func uint16Array() throws -> [UInt16] {
    return try nextArray()
  }
  public func uint8Array() throws -> [UInt8] {
    return try nextArray()
  }
  public func intArray() throws -> [Int] {
    return try nextArray()
  }
  public func int64Array() throws -> [Int64] {
    return try nextArray()
  }
  public func int32Array() throws -> [Int32] {
    return try nextArray()
  }
  public func int16Array() throws -> [Int16] {
    return try nextArray()
  }
  public func int8Array() throws -> [Int8] {
    return try nextArray()
  }
  public func time() throws -> Time {
    return try next()
  }
  public func `enum`<T,S>() throws -> T
    where T: RawRepresentable, S: Unpackable, T.RawValue == S {
      let value = try S(data: self)
      if let v = T(rawValue: value) {
        return v
      } else {
        throw corrupted
      }
  }
  
  public func stringArray() throws -> [String] {
    let count = try count32()
    var array = [String]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(string())
    }
    return array
  }
  public func string8Array() throws -> [String] {
    let count = try count32()
    var array = [String]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(string())
    }
    return array
  }
  public func string32Array() throws -> [String] {
    let count = try count32()
    var array = [String]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(string32())
    }
    return array
  }
  
  
  
  public func uintSet() throws -> Set<UInt> {
    return try nextSet()
  }
  public func uint64Set() throws -> Set<UInt64> {
    return try nextSet()
  }
  public func uint32Set() throws -> Set<UInt32> {
    return try nextSet()
  }
  public func uint16Set() throws -> Set<UInt16> {
    return try nextSet()
  }
  public func uint8Set() throws -> Set<UInt8> {
    return try nextSet()
  }
  public func intSet() throws -> Set<Int> {
    return try nextSet()
  }
  public func int64Set() throws -> Set<Int64> {
    return try nextSet()
  }
  public func int32Set() throws -> Set<Int32> {
    return try nextSet()
  }
  public func int16Set() throws -> Set<Int16> {
    return try nextSet()
  }
  public func int8Set() throws -> Set<Int8> {
    return try nextSet()
  }
  public func stringSet() throws -> Set<String> {
    let count = try count32()
    var array = [String]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(string())
    }
    return Set(array)
  }
  public func string8Set() throws -> Set<String> {
    let count = try count32()
    var array = [String]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(string())
    }
    return Set(array)
  }
  public func string32Set() throws -> Set<String> {
    let count = try count32()
    var array = [String]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      try array.append(string32())
    }
    return Set(array)
  }
}

extension DataReader {
  public func count64(max: Int = 1000000) throws -> Int {
    let v: UInt64 = try next()
    guard v < UInt64(max) else { throw corrupted }
    return Int(v)
  }
  public func count32(max: Int = 1000000) throws -> Int {
    let v: UInt32 = try next()
    guard v < UInt32(max) else { throw corrupted }
    return Int(v)
  }
  public func count16() throws -> Int {
    let v: UInt16 = try next()
    return Int(v)
  }
  public func count8() throws -> Int {
    let v: UInt8 = try next()
    return Int(v)
  }
}


//extension DataReader {
//  open var _reader: DataReader {
//    let length = try! count32()
//    let start = position
//    let end = position + length
//    assert(end <= bytes.count)
//    position = end
//    let slice = bytes[start..<end]
//    let reader = DataReader(slice)
//    return reader
//  }
//  open var _readerArray: [DataReader] {
//    let count = try! count32()
//    var array = [DataReader]()
//    array.reserveCapacity(count)
//    for _ in 0..<count {
//      array.append(_reader)
//    }
//    return array
//  }
//  open var _float: Float {
//    return try! next()
//  }
//  open var _double: Double {
//    return try! next()
//  }
//  open var _bool: Bool {
//    return try! bool()
//  }
//  open var _uint: UInt {
//    return try! next()
//  }
//  open var _uint64: UInt64 {
//    return try! next()
//  }
//  open var _uint32: UInt32 {
//    return try! next()
//  }
//  open var _uint16: UInt16 {
//    return try! next()
//  }
//  open var _uint8: UInt8 {
//    return try! next()
//  }
//  open var _int: Int {
//    return try! next()
//  }
//  open var _int64: Int64 {
//    return try! next()
//  }
//  open var _int32: Int32 {
//    return try! next()
//  }
//  open var _int16: Int16 {
//    return try! next()
//  }
//  open var _int8: Int8 {
//    return try! next()
//  }
//  open var string: String {
//    let count = try! count16()
//    return try! string(count: count)
//  }
//  open var string8: String {
//    return try! string(count: count8())
//  }
//  open var string32: String {
//    return try! string(count: count32())
//  }
//
//  open var _uintArray: [UInt] {
//    return try! nextArray()
//  }
//  open var _uint64Array: [UInt64] {
//    return try! nextArray()
//  }
//  open var _uint32Array: [UInt32] {
//    return try! nextArray()
//  }
//  open var _uint16Array: [UInt16] {
//    return try! nextArray()
//  }
//  open var _uint8Array: [UInt8] {
//    return try! nextArray()
//  }
//  open var _intArray: [Int] {
//    return try! nextArray()
//  }
//  open var _int64Array: [Int64] {
//    return try! nextArray()
//  }
//  open var _int32Array: [Int32] {
//    return try! nextArray()
//  }
//  open var _int16Array: [Int16] {
//    return try! nextArray()
//  }
//  open var _int8Array: [Int8] {
//    return try! nextArray()
//  }
//
//  open var stringArray: [String] {
//    let count = try! count32()
//    var array = [String]()
//    array.reserveCapacity(count)
//    for _ in 0..<count {
//      try! array.append(string())
//    }
//    return array
//  }
//  open var string8Array: [String] {
//    let count = try! count32()
//    var array = [String]()
//    array.reserveCapacity(count)
//    for _ in 0..<count {
//      try! array.append(string())
//    }
//    return array
//  }
//  open var string32Array: [String] {
//    let count = try! count32()
//    var array = [String]()
//    array.reserveCapacity(count)
//    for _ in 0..<count {
//      try! array.append(string32())
//    }
//    return array
//  }
//
//
//
//  open var _uintSet: Set<UInt> {
//    return try! next()
//  }
//  open var _uint64Set: Set<UInt64> {
//    return try! next()
//  }
//  open var _uint32Set: Set<UInt32> {
//    return try! next()
//  }
//  open var _uint16Set: Set<UInt16> {
//    return try! next()
//  }
//  open var _uint8Set: Set<UInt8> {
//    return try! next()
//  }
//  open var _intSet: Set<Int> {
//    return try! next()
//  }
//  open var _int64Set: Set<Int64> {
//    return try! next()
//  }
//  open var _int32Set: Set<Int32> {
//    return try! next()
//  }
//  open var _int16Set: Set<Int16> {
//    return try! next()
//  }
//  open var _int8Set: Set<Int8> {
//    return try! next()
//  }
//  open var stringSet: Set<String> {
//    let count = try! count32()
//    var array = [String]()
//    array.reserveCapacity(count)
//    for _ in 0..<count {
//      try! array.append(string())
//    }
//    return Set(array)
//  }
//  open var string8Set: Set<String> {
//    let count = try! count32()
//    var array = [String]()
//    array.reserveCapacity(count)
//    for _ in 0..<count {
//      try! array.append(string())
//    }
//    return Set(array)
//  }
//  open var string32Set: Set<String> {
//    let count = try! count32()
//    var array = [String]()
//    array.reserveCapacity(count)
//    for _ in 0..<count {
//      try! array.append(string32())
//    }
//    return Set(array)
//  }
//}

*/
*/
