//
//  keys.swift
//  Server
//
//  Created by Дмитрий Козлов on 2/1/18.
//

import Foundation
import SomeFunctions
import SomeData

private extension Int {
  static var currentDay: Int {
    return Int(Time.now / Time.day)
  }
}

class KeyManager: Manager, CustomPath {
  let fileName = "keys.db"
  var keys = [UInt64]()
  var offset = 0
  var lastIndex: Int { return keys.count - 1 + offset }
  subscript (index: Int) -> UInt64? {
    get {
      thread.lock()
      defer { thread.unlock() }
      let moved = index - offset
      if moved >= 0 && moved < keys.count {
        return keys[index - offset]
      } else {
        return nil
      }
    }
  }
  
  func save(data: DataWriter) throws {
    data.compress = false
    data.append(offset)
    data.append(keys)
  }
  func load(data: DataReader) throws {
    data.compress = false
    offset = try data.next()
    keys = try data.next()
  }
  
  var currentDay: Int = .currentDay
  func create() -> (key: UInt64, index: Int) {
    thread.lock()
    defer { thread.unlock() }
    
    let key = UInt64.random()
    keys.append(key)
    return (key,lastIndex)
  }
  
  func check(index: Int, version: Int) -> UInt64? {
    thread.lock()
    defer { thread.unlock() }
    
    checkForUpdates()
    guard version == currentDay else { return nil }
    return keys.safe(index)
  }
  
  private func checkForUpdates() {
    let updated: Int = .currentDay
    if currentDay != updated {
      currentDay = updated
      keys.removeAll(keepingCapacity: true)
    }
  }
}
