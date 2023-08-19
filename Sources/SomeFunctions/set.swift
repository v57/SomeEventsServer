//
//  set.swift
//  SomeFunctions
//
//  Created by Дмитрий Козлов on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension Set {
  public init(_ value: Element) {
    self.init([value])
  }
  public static func += (l: inout Set, r: Set) {
    l.formUnion(r)
  }
  public static func -= (l: inout Set, r: Set) {
    l.subtract(r)
  }
  public static func + (l: Set, r: Set) -> Set {
    return l.union(r)
  }
  public static func - (l: Set, r: Set) -> Set {
    return l.subtracting(r)
  }
  public mutating func merge(to set: Set) -> (added: Set, removed: Set) {
    let added = set - self
    let removed = self - set
    self = set
    return (added,removed)
  }
}


public class SafeSet<T: Hashable> {
  private var set: Set<T>
  private let queue = DispatchQueue(label: "safe-items", attributes: .concurrent)
  public init() {
    set = Set<T>()
  }
  public var count: Int {
    var count = 0
    queue.readWrite {
      count = set.count
    }
    return count
  }
  public func insert(_ item: T) {
    queue.write {
      self.set.insert(item)
    }
  }
  public func remove(_ item: T) {
    queue.write {
      self.set.remove(item)
    }
  }
  public func contains(_ item: T) -> Bool {
    var contains = false
    queue.readWrite {
      contains = set.contains(item)
    }
    return contains
  }
}
