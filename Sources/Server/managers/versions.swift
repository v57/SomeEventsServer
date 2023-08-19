//
//  versions.swift
//  SomeBridge
//
//  Created by Дмитрий Козлов on 12/17/17.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

protocol Versionable {
  static var version: Int { get set }
  static var className: String { get }
}
extension Versionable {
  static var version: Int {
    get {
      return 0
    } set {}
  }
  static var className: String {
    return SomeFunctions.className(Self.self)
  }
}

class Versions: ServerManager, CustomPath {
  var version: Int = 3
  let fileName = "version.db"
  var dbVersion: UInt64 = .random()
  var classes = [String: Versionable.Type]()
  var currentVersions = [String: Int]()
  override func start() {
    var classes = [Versionable.Type]()
    classes.append(Chat.self)
    classes.append(Report.self)
    classes.append(Subscription.self)
    classes.append(User.self)
    classes.append(Content.self)
    classes.append(Message.self)
    classes.forEach {
      let name = $0.className
      self.currentVersions[name] = $0.version
      self.classes[name] = $0
    }
  }
  func save(data: DataWriter) throws {
    data.append(dbVersion)
    data.append(currentVersions.count)
    for (name,version) in currentVersions {
      data.append(name)
      data.append(version)
    }
  }
  func load(data: DataReader) throws {
    classes.values.forEach { $0.version = 0 }
    if version >= 3 {
      dbVersion = try data.next()
      let count = try data.intCount()
      for _ in 0..<count {
        let name: String = try data.next()
        let version: Int = try data.next()
        classes[name]?.version = version
      }
    } else {
      try Chat.version = data.next()
      try Report.version = data.next()
      try Subscription.version = data.next()
      try User.version = data.next()
      try Content.version = data.next()
      if version == 2 {
        try dbVersion = data.next()
      }
      for (name,version) in currentVersions {
        classes[name]?.version = version
      }
    }
  }
}
