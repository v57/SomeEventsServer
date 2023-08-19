//
//  random.swift
//  SomeFunctions
//
//  Created by Дмитрий Козлов on 2/12/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

private let psd = 1488_911_420
private let x64 = MemoryLayout<Int>.size == MemoryLayout<Int64>.size

postfix operator %
public postfix func % (l: Int) -> Bool {
  return Double(l) / 100 < Double.random()
}
public postfix func % (l: Double) -> Bool {
  return Double(l) / 100 < Double.random()
}
postfix operator %%
public postfix func %% (l: Int) -> Bool {
  return Double(l) / 100 < Double.seed()
}
public postfix func %% (l: Double) -> Bool {
  return Double(l) / 100 < Double.seed()
}
public postfix func %% (l: Float) -> Bool {
  return Double(l) / 100 < Double.seed()
}

infix operator --
public func -- (l: Int, r: Int) -> Int {
  return .random(min: l, max: r)
}
public func -- (l: Float, r: Float) -> Float {
  return .random(min: l, max: r)
}
public func -- (l: Double, r: Double) -> Double {
  return .random(min: l, max: r)
}

extension Double {
  public static func random() -> Double {
    return Double(UInt64.random()) / Double(UInt64.max)
  }
  public static func random(max: Double) -> Double {
    return .random() * max
  }
  public static func random(min: Double, max: Double) -> Double {
    return min + .random() * (max - min)
  }
  public static func seed(_ x: Int, _ y: Int) -> Double {
    return Double(UInt64.seed(x, y)) / 0xffffffffffffffff
  }
  public static func seed(_ x: UInt64, _ y: UInt64) -> Double {
    return Double(UInt64.seed(x, y)) / 0xffffffffffffffff
  }
  public static func seed() -> Double { return .seed(psd, .unique) }
}

extension Float {
  public static func random() -> Float {
    return Float(UInt32.random()) / Float(UInt32.max)
  }
  public static func random(max: Float) -> Float {
    return .random() * max
  }
  public static func random(min: Float, max: Float) -> Float {
    return min + .random() * (max - min)
  }
  public static func seed(_ x: Int, _ y: Int) -> Float {
    return Float(UInt32.seed(x, y)) / 0xffffffff
  }
  public static func seed() -> Float { return .seed(psd, .unique) }
}

extension UInt {
  public static func random() -> UInt {
    return x64 ? UInt(UInt64.random()) : UInt(UInt32.random())
  }
  public static func random(max: UInt) -> UInt {
    return x64 ? UInt(UInt64.random(max: max)) : UInt(UInt64.random(max: max))
  }
  public static func random(min: UInt, max: UInt) -> UInt {
    return x64 ? UInt(UInt64.random(min: min, max: max)) : UInt(UInt64.random(min: min, max: max))
  }
  public static func seed(_ x: Int, _ y: Int) -> UInt {
    return x64 ? UInt(UInt64.seed(x,y)) : UInt(UInt32.seed(x,y))
  }
  public static func seed() -> UInt { return .seed(psd, .unique) }
  private static var _unique: UInt = 0
  public static var unique: UInt {
    _unique += 1
    return _unique
  }
}

extension Int {
  public static func random() -> Int {
    return x64 ? Int(Int64.random()) : Int(Int32.random())
  }
  public static func random(max: Int) -> Int {
    return x64 ? Int(Int64.random(max: max)) : Int(Int64.random(max: max))
  }
  public static func random(min: Int, max: Int) -> Int {
    return x64 ? Int(Int64.random(min: min, max: max)) : Int(Int64.random(min: min, max: max))
  }
  public static func seed(_ x: Int, _ y: Int) -> Int {
    return x64 ? Int(Int64.seed(x,y)) : Int(Int32.seed(x,y))
  }
  public static func seed() -> Int { return .seed(psd, .unique) }
  private static var _unique: Int = 0
  public static var unique: Int {
    _unique += 1
    return _unique
  }
  
  func uint64() -> UInt64 {
    return UInt64(UInt(bitPattern: self))
  }
  func uint32() -> UInt32 {
    return UInt32(UInt(bitPattern: self))
  }
}

extension UInt64 {
  public static func random() -> UInt64 { return .random(in: UInt64.min...UInt64.max) }
  public static func random(max: UInt64) -> UInt64 {
    return UInt64(Double.random() * Double(max))
  }
  public static func random(max: UInt) -> UInt64 {
    return UInt64(Double.random() * Double(max))
  }
  public static func random(max: Int) -> UInt64 {
    return UInt64(Double.random() * Double(max))
  }
  public static func random(min: UInt64, max: UInt64) -> UInt64 {
    return min + .random(max: max - min)
  }
  public static func random(min: UInt, max: UInt) -> UInt64 {
    let min = UInt64(min)
    let max = UInt64(max)
    return min + .random(max: max - min)
  }
  public static func random(min: Int, max: Int) -> UInt64 {
    let min = UInt64(min)
    let max = UInt64(max)
    return min + .random(max: max - min)
  }
  
  public static func seed(_ x: UInt64, _ y: UInt64) -> UInt64 {
    var y = y
    y = (y >> 13) ^ y
    y = (y &* (y &* y &* x &+ 0xc0c1_fa9907_1488_00) &+ 13763125891376312589) & 0xffffffffffffffff
    let inner = (y &* (y &* y &* 1573115731 &+ 789221789221) &+ 13763125891376312589) & 0xffffffffffffffff
    return inner
  }
  public static func seed(_ x: Int, _ y: Int) -> UInt64 {
    return seed(UInt64(x),UInt64(y))
  }
  public static func seed() -> UInt64 { return .seed(psd, .unique) }
  private static var _unique: UInt64 = 0
  public static var unique: UInt64 {
    _unique += 1
    return _unique
  }
  func int64() -> Int64 {
    return Int64(bitPattern: self)
  }
  #if __LP64__
  func int() -> Int {
    return Int(bitPattern: UInt(self))
  }
  func uint() -> UInt {
    return UInt(self)
  }
  #endif
}

extension UInt32 {
  public static func random() -> UInt32 { return UInt32.random(in: UInt32.min..<UInt32.max) }
  
  public static func random(max: UInt32) -> UInt32 {
    return UInt32.random(in: 0...max)
  }
  public static func random(max: UInt) -> UInt32 {
    return UInt32.random(in: 0...UInt32(max))
  }
  public static func random(max: Int) -> UInt32 {
    return UInt32.random(in: 0...UInt32(max))
  }
  
  public static func random(min: UInt32, max: UInt32) -> UInt32 {
    return UInt32.random(in: min...max)
  }
  public static func random(min: UInt, max: UInt) -> UInt32 {
    return UInt32.random(in: UInt32(min)...UInt32(max))
  }
  public static func random(min: Int, max: Int) -> UInt32 {
    return UInt32.random(in: UInt32(min)...UInt32(max))
  }
  
  public static func seed(_ x: UInt32, _ y: UInt32) -> UInt32 {
    var y = y
    y = (y >> 13) ^ y
    y = (y &* (y &* y &* x &+ 19990303) &+ 1376312589) & 0xffffffff
    let inner = (y &* (y &* y &* 15731 &+ 789221) &+ 1376312589) & 0xffffffff
    return inner
  }
  public static func seed(_ x: Int, _ y: Int) -> UInt32 {
    return seed(x.uint32(), y.uint32())
  }
  public static func seed() -> UInt32 { return .seed(psd, .unique) }
  private static var _unique: UInt32 = 0
  public static var unique: UInt32 {
    _unique += 1
    return _unique
  }
  func int32() -> Int32 {
    return Int32(bitPattern: self)
  }
  #if !__LP64__
  func int() -> Int {
    return Int(bitPattern: UInt(self))
  }
  func uint() -> UInt {
    return UInt(self)
  }
  #endif
}

extension Int64 {
  public static func random() -> Int64 { return Int64(bitPattern: UInt64.random()) }
  public static func random(max: Int64) -> Int64 {
    return Int64(Double.random() * Double(max))
  }
  public static func random(max: Int) -> Int64 {
    return Int64(Double.random() * Double(max))
  }
  public static func random(min: Int64, max: Int64) -> Int64 {
    return min + .random(max: max - min)
  }
  public static func random(min: Int, max: Int) -> Int64 {
    let min = Int64(min)
    let max = Int64(max)
    return min + .random(max: max - min)
  }
  
  public static func seed(_ x: Int64, _ y: Int64) -> Int64 {
    return UInt64.seed(x.uint64(), y.uint64()).int64()
  }
  public static func seed(_ x: Int, _ y: Int) -> Int64 {
    return UInt64.seed(x.uint64(), y.uint64()).int64()
  }
  public static func seed() -> Int64 { return .seed(psd, .unique) }
  private static var _unique: Int64 = 0
  public static var unique: Int64 {
    _unique += 1
    return _unique
  }
  func uint64() -> UInt64 {
    return UInt64(bitPattern: self)
  }
}

extension Int32 {
  public static func random() -> Int32 { return Int32(bitPattern: UInt32.random()) }
  public static func random(max: Int32) -> Int32 {
    return Int32(Double.random() * Double(max))
  }
  public static func random(max: Int) -> Int32 {
    return Int32(Double.random() * Double(max))
  }
  public static func random(min: Int32, max: Int32) -> Int32 {
    return min + .random(max: max - min)
  }
  public static func random(min: Int, max: Int) -> Int32 {
    let min = Int32(min)
    let max = Int32(max)
    return min + .random(max: max - min)
  }
  
  public static func seed(_ x: Int32, _ y: Int32) -> Int32 {
    return UInt32.seed(x.uint32(), y.uint32()).int32()
  }
  public static func seed(_ x: Int, _ y: Int) -> Int32 {
    return UInt32.seed(x.uint32(), y.uint32()).int32()
  }
  public static func seed() -> Int32 { return .seed(psd, .unique) }
  private static var _unique: Int32 = 0
  public static var unique: Int32 {
    _unique += 1
    return _unique
  }
  func uint32() -> UInt32 {
    return UInt32(bitPattern: self)
  }
}

extension Bool {
  public static func random() -> Bool { return UInt32.random(in: 0...1) == 1 }
  public static func seed() -> Bool { return UInt32.seed() & 1 == 0 }
}






