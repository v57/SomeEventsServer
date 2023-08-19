//
//  Data.swift
//  Some
//
//  Created by Дмитрий Козлов on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import SomeFunctions

public extension Data {
  init<T>(_ values: Array<T>) where T: Primitive {
    var values = values
    self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
  }
  init<T>(_ values: Set<T>) where T: Primitive {
    var values = values
    self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
  }
  init<T>(_ values: ArraySlice<T>) where T: Primitive {
    var values = values
    self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
  }
  init<T>(_ value: T) where T: Primitive {
    var value = value
    self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
  }
  init<T,S>(_ value: T) where T: RawRepresentable, S: Primitive, T.RawValue == S {
    self.init(value.rawValue)
  }
  mutating func append<T,S>(_ value: T) where T: RawRepresentable, S: Primitive, T.RawValue == S {
    append(value.rawValue)
  }
  mutating func append<T>(_ values: Array<T>) where T: Primitive {
    var values = values
    append(UnsafeBufferPointer(start: &values, count: values.count))
  }
  mutating func append<T>(_ values: Set<T>) where T: Primitive {
    var values = values
    append(UnsafeBufferPointer(start: &values, count: values.count))
  }
  mutating func append<T>(_ values: ArraySlice<T>) where T: Primitive {
    var values = values
    append(UnsafeBufferPointer(start: &values, count: values.count))
  }
  mutating func append<T>(_ value: T) where T: Primitive {
    var value = value
    append(UnsafeBufferPointer(start: &value, count: 1))
  }
  mutating func replace<T>(at index: Int, with value: T) where T: Primitive {
    var value = value
    let end = index + MemoryLayout<T>.size
    replaceSubrange(index..<end , with: UnsafeBufferPointer(start: &value, count: 1))
  }
  func convert<T,S>() throws -> T where T: RawRepresentable, S: Primitive, T.RawValue == S {
    if let value = T(rawValue: convert()) {
      return value
    } else {
      throw corrupted
    }
  }
  func convert<T: Primitive>() -> T {
    return withUnsafeBytes { $0.pointee }
  }
  func convert<T>() -> Array<T> where T: Primitive {
    return withUnsafeBytes {
      Array(UnsafeBufferPointer(start: $0, count: count / MemoryLayout<T>.stride))
    }
  }
  func convert<T>() -> Set<T> where T: Primitive {
    return withUnsafeBytes {
      Set(UnsafeBufferPointer(start: $0, count: count / MemoryLayout<T>.stride))
    }
  }
  func convert<T>() -> ArraySlice<T> where T: Primitive {
    return withUnsafeBytes {
      ArraySlice(UnsafeBufferPointer(start: $0, count: count / MemoryLayout<T>.stride))
    }
  }
  var rawPointer: UnsafeRawPointer {
    var pointer: UnsafeRawPointer!
    data.withUnsafeBytes { (uint8Ptr: UnsafePointer<UInt8>) in
      pointer = UnsafeRawPointer(uint8Ptr)
    }
    return pointer
  }
}

