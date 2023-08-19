//
//  DataRepresentable.swift
//  Some
//
//  Created by Дмитрий Козлов on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import SomeFunctions

public protocol DataDecodable {
  func save(data: DataWriter)
}

public protocol DataRepresentable: DataDecodable {
  init(data: DataReader) throws
}

public protocol DataLoadable: DataDecodable {
  init()
  func load(data: DataReader) throws
}

public protocol Storable {
  static var keys: [PartialKeyPath<Self>] { get }
  init()
}

extension String: DataRepresentable {
  public init(data: DataReader) throws {
    if let string = try String(data: data.next(), encoding: .utf8) {
      self = string
    } else {
      throw corrupted
    }
  }
  public func save(data: DataWriter) {
    data.append(self.data(using: .utf8)!)
  }
}

extension Data: DataRepresentable {
  public init(data: DataReader) throws {
    let count = try data.intCount()
    self = try data.subdata(count)
  }
  public func save(data: DataWriter) {
    data.append(count)
    data.data.append(self)
  }
}

extension vec2 {
  
}
