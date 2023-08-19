//
//  options.swift
//  SomeFunctions
//
//  Created by Дмитрий Козлов on 12/15/17.
//

import Foundation

extension UInt8 {
  public func optionSet<T>() -> Set<T> where T: RawRepresentable, T.RawValue == UInt8 {
    var set = Set<T>()
    for i in UInt8(0)..<UInt8(8) {
      guard self[i] else { continue }
      guard let value = T(rawValue: i) else { break }
      set.insert(value)
    }
    return set
  }
}

public extension RawRepresentable where RawValue: BinaryInteger {
  public static var count: Int {
    var i: RawValue = 0
    while Self(rawValue: i) != nil {
      i += 1
    }
    return Int(i)
  }
  public static func forEach(_ action: (Self)->()) {
    var i: RawValue = 0
    while let value = Self(rawValue: i) {
      action(value)
      i += 1
    }
  }
}

public extension RawRepresentable where RawValue: Comparable {
  public static func <(lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
  public static func <=(lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue <= rhs.rawValue
  }
  public static func >=(lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue >= rhs.rawValue
  }
  public static func >(lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue > rhs.rawValue
  }
}

extension RawRepresentable where RawValue == UInt8 {
  public typealias Set = Options<Self,UInt8>
  public typealias Set16 = Options<Self,UInt16>
  public typealias Set32 = Options<Self,UInt32>
  public typealias Set64 = Options<Self,UInt64>
}

public struct Options<Enum,RawValue>: RawRepresentable
where Enum: RawRepresentable, RawValue: BinaryInteger, Enum.RawValue == UInt8 {
  public var rawValue: RawValue
  public var isEmpty: Bool {
    return rawValue == 0
  }
  public init() {
    rawValue = 0
  }
  public init(_ array: [Enum]) {
    rawValue = 0
    for v in array {
      rawValue[v.rawValue] = true
    }
  }
  public init(_ array: Enum...) {
    rawValue = 0
    for v in array {
      rawValue[v.rawValue] = true
    }
  }
  public init(rawValue: RawValue) {
    self.rawValue = rawValue
  }
  public subscript(_ value: Enum) -> Bool {
    get {
      return contains(value)
    } set {
      if newValue {
        insert(value)
      } else {
        remove(value)
      }
    }
  }
  
  /// |
  public func union(_ other: Options<Enum, RawValue>) -> Options<Enum, RawValue> {
    return Options(rawValue: rawValue | other.rawValue)
  }
  
  /// &
  public func intersection(_ other: Options<Enum, RawValue>) -> Options<Enum, RawValue> {
    return Options(rawValue: rawValue & other.rawValue)
  }
  
  /// ^ returns set of changed values
  public func symmetricDifference(_ other: Options<Enum, RawValue>) -> Options<Enum, RawValue> {
    return Options(rawValue: rawValue ^ other.rawValue)
  }
  
  public mutating func formUnion(_ other: Options<Enum, RawValue>) {
    rawValue |= other.rawValue
  }
  
  public mutating func formIntersection(_ other: Options<Enum, RawValue>) {
    rawValue &= other.rawValue
  }
  
  public mutating func formSymmetricDifference(_ other: Options<Enum, RawValue>) {
    rawValue ^= other.rawValue
  }
  public func contains(_ value: Enum) -> Bool {
    return rawValue[value.rawValue]
  }
  public mutating func set(_ value: Enum, _ shouldInsert: Bool) {
    if shouldInsert {
      insert(value)
    } else {
      remove(value)
    }
  }
  public mutating func insert(_ value: Enum) {
    rawValue[value.rawValue] = true
  }
  public mutating func remove(_ value: Enum) {
    rawValue[value.rawValue] = false
  }
}


extension Options: Numeric {
  public typealias Magnitude = RawValue.Magnitude
  public typealias IntegerLiteralType = Int
  public var magnitude: RawValue.Magnitude {
    return rawValue.magnitude
  }
  public init?<T>(exactly source: T) where T : BinaryInteger {
    rawValue = RawValue(source)
  }
  public init(integerLiteral value: Options.IntegerLiteralType) {
    rawValue = RawValue(value)
  }
  public static func *(lhs: Options<Enum, RawValue>, rhs: Options<Enum, RawValue>) -> Options<Enum, RawValue> {
    return Options(rawValue: lhs.rawValue * rhs.rawValue)
  }
  public static func *=(lhs: inout Options<Enum, RawValue>, rhs: Options<Enum, RawValue>) {
    lhs.rawValue *= rhs.rawValue
  }
  public static func +(lhs: Options<Enum, RawValue>, rhs: Options<Enum, RawValue>) -> Options<Enum, RawValue> {
    return Options(rawValue: lhs.rawValue + rhs.rawValue)
  }
  public static func +=(lhs: inout Options<Enum, RawValue>, rhs: Options<Enum, RawValue>) {
    lhs.rawValue += rhs.rawValue
  }
  public static func -(lhs: Options<Enum, RawValue>, rhs: Options<Enum, RawValue>) -> Options<Enum, RawValue> {
    return Options(rawValue: lhs.rawValue - rhs.rawValue)
  }
  public static func -=(lhs: inout Options<Enum, RawValue>, rhs: Options<Enum, RawValue>) {
    lhs.rawValue -= rhs.rawValue
  }
}

extension Options: CustomStringConvertible {
  public var description: String {
    var string = ""
    for i in 0..<Enum.count {
      if rawValue[i] {
        string += "1,"
      } else {
        string += "0,"
      }
    }
    string.removeLast()
    return string
  }
  public func description(withInit createEnum: (Enum.RawValue)->(Enum?)) -> String {
    var string = ""
    for i in 0..<Enum.count {
      let value = createEnum(Enum.RawValue(i))!
      string += "\n\(value): \(rawValue[i])"
    }
    if string.isEmpty {
      return "empty"
    } else {
      return string
    }
  }
}

extension BinaryInteger {
  public subscript<T: BinaryInteger>(index: T) -> Bool {
    get {
      return self & (1 << index) != 0
    }
    set {
      if newValue {
        self = self | (1 << index)
      } else {
        self = self & ~(1 << index)
      }
    }
  }
}
