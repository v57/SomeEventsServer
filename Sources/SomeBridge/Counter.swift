//
//  IDCounter.swift
//  SomeBridge
//
//  Created by Дмитрий Козлов on 11/29/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import SomeData

public protocol Countable {
  static var ids: Counter<ID> { get set }
}
extension Countable {
  public static var id: ID { return ids.next() }
}

public struct Counter<Value: FixedWidthInteger & Primitive>: RawRepresentable {
  public typealias RawValue = Value
  
  public var rawValue: Value
  public init?(rawValue: Value) {
    self.rawValue = rawValue
  }
  public init(_ rawValue: Value) {
    self.rawValue = rawValue
  }
  public init() {
    rawValue = -1
  }
  public mutating func next() -> Value {
    rawValue = rawValue &+ 1
    if rawValue == .max {
      rawValue = 0
    }
    return rawValue
  }
}

public struct NegativeCounter<Value: FixedWidthInteger & Primitive>: RawRepresentable {
  public typealias RawValue = Value
  
  public var rawValue: Value
  public init?(rawValue: Value) {
    self.rawValue = rawValue
  }
  public init(_ rawValue: Value) {
    self.rawValue = rawValue
  }
  public init() {
    rawValue = 0
  }
  public mutating func next() -> Value {
    rawValue = rawValue &- 1
    if rawValue == .min {
      rawValue = 0
    }
    return rawValue
  }
}

