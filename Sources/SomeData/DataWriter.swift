//
//  DataWriter.swift
//  Some
//
//  Created by Дмитрий Козлов on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import SomeFunctions

public struct WriterPointer<T: Primitive> {
  public let data: DataWriter
  public let position: Int
  public init(_ data: DataWriter) {
    self.data = data
    position = data.count
    data.data.append(T())
  }
  public func set(_ value: T) {
    data.data.replace(at: position, with: value)
  }
}

public class DataWriter: DataRepresentable {
  public var data: Data
  public var count: Int { return data.count }
  public var isEmpty: Bool { return data.isEmpty }
  public var base64: String { return data.base64EncodedString() }
  public var compress = true
  public init(data: Data) {
    self.data = data
  }
  public init() {
    data = Data()
  }
  public required init(data: DataReader) throws {
    self.data = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(self.data)
  }
  public func copy() -> DataWriter {
    return DataWriter(data: data.copy())
  }
  
  public func replace(at index: Int, with data: Data) {
    self.data.replaceSubrange(index..<index+data.count, with: data)
  }
  
  // Number
  public func append<T: Primitive>(_ value: T) {
    value.write(to: &data)
  }
  public func append<T: Primitive>(_ value: T...) {
    value.forEach { $0.write(to: &data) }
  }
  
  // [Number]
  public func append<T>(_ value: Array<T>) where T: Primitive {
    var value = value
    append(value.count)
    if compress {
      for v in value {
        v.write(to: &data)
      }
    } else {
      data.append(UnsafeBufferPointer(start: &value, count: value.count))
    }
  }
  public func append<T>(_ value: Set<T>) where T: Primitive {
    var value = value
    append(value.count)
    if compress {
      for v in value {
        v.write(to: &data)
      }
    } else {
      data.append(UnsafeBufferPointer(start: &value, count: value.count))
    }
  }
  public func append<T>(_ value: ArraySlice<T>) where T: Primitive {
    var value = value
    append(value.count)
    if compress {
      for v in value {
        v.write(to: &data)
      }
    } else {
      data.append(UnsafeBufferPointer(start: &value, count: value.count))
    }
  }
  
  // Enum
  public func append<T,S>(_ value: T) where T: RawRepresentable, S: Primitive, T.RawValue == S {
    data.append(value)
  }
  
  // Data
  public func append(_ value: DataDecodable) {
    value.save(data: self)
  }
  public func append(_ value: DataDecodable?) {
    append(value != nil)
    guard let value = value else { return }
    value.save(data: self)
  }
  // [Data]
  public func append<T>(_ value: Array<T>) where T: DataDecodable {
    append(value.count)
    value.forEach {
      append($0)
    }
  }
  public func append<T>(_ value: Set<T>) where T: DataDecodable {
    append(value.count)
    value.forEach {
      append($0)
    }
  }
}

