//
//  vector.swift
//  SomeFunctions
//
//  Created by Дмитрий Козлов on 12/20/17.
//

import Swift

public struct vec2<T: Primitive>: Hashable, DataRepresentable {
  public var x: T
  public var y: T
  public init(_ x: T, _ y: T) {
    self.x = x
    self.y = y
  }
  public init() {
    self.x = T()
    self.y = T()
  }
  public init(data: DataReader) throws {
    try x = data.next()
    try y = data.next()
  }
  public func save(data: DataWriter) {
    data.append(x)
    data.append(y)
  }
  public var hashValue: Int {
    return x.hashValue &+ y.hashValue
  }
  public static func ==(l: vec2<T>, r: vec2<T>) -> Bool {
    return l.x == r.x && l.y == r.y
  }
}
public struct vec3<T: Primitive>: Hashable, DataRepresentable {
  public var x: T
  public var y: T
  public var z: T
  public init(_ x: T, _ y: T, _ z: T) {
    self.x = x
    self.y = y
    self.z = z
  }
  public init() {
    self.x = T()
    self.y = T()
    self.z = T()
  }
  public init(data: DataReader) throws {
    try x = data.next()
    try y = data.next()
    try z = data.next()
  }
  public func save(data: DataWriter) {
    data.append(x)
    data.append(y)
    data.append(z)
  }
  public var hashValue: Int {
    return x.hashValue &+ y.hashValue &+ z.hashValue
  }
  public static func ==(l: vec3<T>, r: vec3<T>) -> Bool {
    return l.x == r.x && l.y == r.y && l.z == r.z
  }
}
public struct vec4<T: Primitive>: Hashable, DataRepresentable {
  public var x: T
  public var y: T
  public var z: T
  public var w: T
  public init(_ x: T, _ y: T, _ z: T, _ w: T) {
    self.x = x
    self.y = y
    self.z = z
    self.w = w
  }
  public init() {
    self.x = T()
    self.y = T()
    self.z = T()
    self.w = T()
  }
  public init(data: DataReader) throws {
    try x = data.next()
    try y = data.next()
    try z = data.next()
    try w = data.next()
  }
  public func save(data: DataWriter) {
    data.append(x)
    data.append(y)
    data.append(z)
    data.append(w)
  }
  public var hashValue: Int {
    return x.hashValue &+ y.hashValue &+ z.hashValue &+ w.hashValue
  }
  public static func ==(l: vec4<T>, r: vec4<T>) -> Bool {
    return l.x == r.x && l.y == r.y && l.z == r.z && l.w == r.w
  }
}
