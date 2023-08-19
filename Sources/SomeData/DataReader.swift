//
//  DataReader.swift
//  Some
//
//  Created by Дмитрий Козлов on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import SomeFunctions

open class DataReader: DataRepresentable {
  public var data: Data
  public var position = 0
  public var count: Int { return data.count }
  public var isEmpty: Bool { return data.isEmpty }
  public var bytesLeft: Int { return count - position }
  public var compress = true
  public var safeLimits = 1000000
  public init() {
    self.data = Data()
  }
  public init(data: Data) {
    self.data = data
  }
  public required init(data: DataReader) throws {
    self.data = try data.next()
  }
  public init?(base64: String) {
    guard let data = Data(base64Encoded: base64) else { return nil }
    self.data = data
  }
  public init?(url: FileURL) {
    if let data = Data(contentsOf: url) {
      self.data = data
    } else {
      return nil
    }
  }
  public func save(data: DataWriter) {
    data.append(self.data)
  }
  func convert<T>() throws -> T where T: Primitive {
    return try subdata(MemoryLayout<T>.size).convert()
  }
  public func next<T>() throws -> T where T: Primitive {
    return try T.init(data: self)
  }
  public func check(count: Int, max: Int) throws {
    guard count <= bytesLeft else { throw corrupted }
    guard count >= 0 else { throw corrupted }
    guard count < max else { throw corrupted }
  }
  public func next<T>() throws -> Array<T> where T: Primitive {
    if compress {
      let count: Int = try intCount()
      var array = Array<T>()
      array.reserveCapacity(count)
      for _ in 0..<count {
        try array.append(next())
      }
      return array
    } else {
      let count: Int = try next() * MemoryLayout<T>.size
      return try subdata(count).withUnsafeBytes {
        Array<T>.init(UnsafeBufferPointer(start: $0, count: count / MemoryLayout<T>.stride))
      }
    }
  }
  public func next<T>() throws -> Set<T> where T: Primitive {
    if compress {
      let count: Int = try intCount()
      var array = Set<T>()
      array.reserveCapacity(count)
      for _ in 0..<count {
        try array.insert(next())
      }
      return array
    } else {
      let count: Int = try next() * MemoryLayout<T>.size
      return try subdata(count).withUnsafeBytes {
        Set<T>.init(UnsafeBufferPointer(start: $0, count: count / MemoryLayout<T>.stride))
      }
    }
  }
  #if !__LP64__
  public func next() throws -> [Int] {
    let array: [Int64] = try next()
    return array.map { Int($0) }
  }
  public func next() throws -> [UInt] {
    let array: [UInt64] = try next()
    return array.map { UInt($0) }
  }
  #endif
  public func next<T,S>() throws -> T where T: RawRepresentable, S: Primitive, T.RawValue == S {
    let value: S = try convert()
    if let v = T(rawValue: value) {
      return v
    } else {
      throw corrupted
    }
  }
  public func next<T>() throws -> T where T: DataRepresentable {
    return try T.init(data: self)
  }
  public func next<T>() throws -> Array<T> where T: DataRepresentable {
    let count: Int = try intCount()
    var array = Array<T>()
    array.reserveCapacity(count)
    for _ in 0..<count {
      let value = try T.init(data: self)
      array.append(value)
    }
    return array
  }
  public func next<T>() throws -> Set<T> where T: DataRepresentable & Hashable {
    let count: Int = try intCount()
    var set = Set<T>()
    set.reserveCapacity(count)
    for _ in 0..<count {
      let value = try T.init(data: self)
      set.insert(value)
    }
    return set
  }
  public func next<T>() throws -> T? where T: DataRepresentable {
    guard try bool() else { return nil }
    return try T.init(data: self)
  }
  
  public func load<T>(_ value: T) throws where T: DataLoadable {
    return try value.load(data: self)
  }
  public func load<T>(_ value: Array<T>) throws where T: DataLoadable {
    for v in value {
      try v.load(data: self)
    }
  }
  public func load<T>(_ value: Set<T>) throws where T: DataLoadable {
    for v in value {
      try v.load(data: self)
    }
  }
  
  public func update<T>(_ value: Array<T>) where T: DataLoadable {
    for v in value {
      try? v.load(data: self)
    }
  }
  public func update<T>(_ value: Set<T>) where T: DataLoadable {
    for v in value {
      try? v.load(data: self)
    }
  }
  public func update<T>(_ value: ArraySlice<T>) where T: DataLoadable {
    for v in value {
      try? v.load(data: self)
    }
  }
  
  public func subdata(_ count: Int) throws -> Data {
    guard position + count <= data.count else { throw corrupted }
    let subdata = data.subdata(in: position..<position+count)
    position += count
    return subdata
  }
  
  // долбаеб не используй это вместо int() только для того,
  // чтобы получить положительное число
  public func intCount() throws -> Int {
    let count = try int()
    try check(count: count, max: safeLimits)
    return count
  }
  public func intCount(max: Int) throws -> Int {
    let count = try int()
    try check(count: count, max: max)
    return count
  }
  public func `enum`<T,S>() throws -> T where T: RawRepresentable, S: Primitive, T.RawValue == S {
    return try next()
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
    return try next()
  }
  public func bool() throws -> Bool {
    return try next()
  }
  public func float() throws -> Float {
    return try next()
  }
  public func double() throws -> Double {
    return try next()
  }
  
  public func uintArray() throws -> Array<UInt> {
    return try next()
  }
  public func uint64Array() throws -> Array<UInt64> {
    return try next()
  }
  public func uint32Array() throws -> Array<UInt32> {
    return try next()
  }
  public func uint16Array() throws -> Array<UInt16> {
    return try next()
  }
  public func uint8Array() throws -> Array<UInt8> {
    return try next()
  }
  public func intArray() throws -> Array<Int> {
    return try next()
  }
  public func int64Array() throws -> Array<Int64> {
    return try next()
  }
  public func int32Array() throws -> Array<Int32> {
    return try next()
  }
  public func int16Array() throws -> Array<Int16> {
    return try next()
  }
  public func int8Array() throws -> Array<Int8> {
    return try next()
  }
  public func stringArray() throws -> Array<String> {
    return try next()
  }
  
  public func uintSet() throws -> Set<UInt> {
    return try next()
  }
  public func uint64Set() throws -> Set<UInt64> {
    return try next()
  }
  public func uint32Set() throws -> Set<UInt32> {
    return try next()
  }
  public func uint16Set() throws -> Set<UInt16> {
    return try next()
  }
  public func uint8Set() throws -> Set<UInt8> {
    return try next()
  }
  public func intSet() throws -> Set<Int> {
    return try next()
  }
  public func int64Set() throws -> Set<Int64> {
    return try next()
  }
  public func int32Set() throws -> Set<Int32> {
    return try next()
  }
  public func int16Set() throws -> Set<Int16> {
    return try next()
  }
  public func int8Set() throws -> Set<Int8> {
    return try next()
  }
  public func stringSet() throws -> Set<String> {
    return try next()
  }
  
  
  public func uintFull() throws -> UInt {
    return try convert()
  }
  public func uint64Full() throws -> UInt64 {
    return try convert()
  }
  public func uint32Full() throws -> UInt32 {
    return try convert()
  }
  public func intFull() throws -> Int {
    return try convert()
  }
  public func int64Full() throws -> Int64 {
    return try convert()
  }
  public func int32Full() throws -> Int32 {
    return try convert()
  }
  public func array<T>(body: ()throws->(T)) throws -> [T] {
    let count = try intCount()
    var array = [T]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      let value = try body()
      array.append(value)
    }
    return array
  }
  //  func next<T,S>() throws -> T where T: RawRepresentable, S: Primitive, T.RawValue == S {
  //
  //  }
  //  func next<T>() throws -> T where T: Primitive {
  //
  //  }
}

extension DataReader: CustomStringConvertible {
  public var description: String {
    var string = "DataReader \(position)/\(count)"
    let first = min(16,count)
    let last = max(count-16,0)
    let previous = max(position-16,0)
    let next = min(position+16,count)
    
    string.addLine("first: \(data[0..<first].hexString)")
    string.addLine("last: \(data[last..<count].hexString)")
    string.addLine("previous: \(data[previous..<position].hexString)")
    string.addLine("next: \(data[position..<next].hexString)")
    
    return string
  }
}
