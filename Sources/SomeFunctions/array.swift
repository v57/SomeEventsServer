//
//  array.swift
//  SomeFunctions
//
//  Created by Дмитрий Козлов on 2/12/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension Collection {
  public func sum<T: Numeric>(by: (Iterator.Element)->(T)) -> T {
    var a: T = 0
    for n in self {
      a += by(n)
    }
    return a
  }
}

public struct Weak<T: AnyObject> {
  public weak var value : T?
  public init (_ value: T) {
    self.value = value
  }
}

public func unwrap<T>(array: [T?]) -> [T] {
  var array2 = [T]()
  for value in array {
    guard let a = value else { continue }
    array2.append(a)
  }
  return array2
}

public class WeakArray<T: AnyObject> {
  private var content = [Weak<T>]()
  public init() {}
  public var isEmpty: Bool { return count == 0 }
  public var count: Int {
    reap()
    return content.count
  }
  public var allObjects: [T] {
    reap()
    var array = [T]()
    for object in content {
      guard let value = object.value else { continue }
      array.append(value)
    }
    return array
  }
  
  public func append(_ object: T) {
    content.append(Weak(object))
  }
  
  private func reap() {
    content = content.filter { nil != $0.value }
  }
}

extension Array where Element: Equatable {
  public mutating func remove(contentsOf array: [Element]) {
    for object in array {
      self.remove(object)
    }
  }
  
  public mutating func remove(_ object: Element) {
    if let index = self.index(of: object) {
      self.remove(at: index)
    }
  }
  public mutating func insert(_ object: Element) {
    if contains(object) {
      return
    } else {
      append(object)
    }
  }
}

public enum ArrayOverride {
  case first, last, none
}

extension Array {
  public mutating func append(_ newElement: Element, max: Int, override: ArrayOverride) {
    assert(max > 0)
    guard count >= max else {
      append(newElement)
      return
    }
    switch override {
    case .first:
      removeFirst()
      append(newElement)
    case .last:
      removeLast()
      append(newElement)
    case .none:
      return
    }
  }
  public mutating func sortedInsert(_ element: Element, isOrderedBefore: (Element, Element) -> Bool) {
    guard count > 0 else {
      append(element)
      return }
    if isOrderedBefore(element,first!) {
      insert(element, at: 0)
    } else if isOrderedBefore(last!,element) {
      append(element)
    } else {
      let i = index(for: element, isOrderedBefore: isOrderedBefore)
      self.insert(element, at: i)
    }
  }
  public func index(for elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
    var lo = 0
    var hi = self.count - 1
    while lo <= hi {
      let mid = (lo + hi)/2
      if isOrderedBefore(self[mid], elem) {
        lo = mid + 1
      } else if isOrderedBefore(elem, self[mid]) {
        hi = mid - 1
      } else {
        return mid // found at position mid
      }
    }
    return lo // not found, would be inserted at position lo
  }
  public func index<T: Comparable>(for e: T, compareWith: (Element)->T) -> Int {
    guard count > 0 else { return 0 }
    if e < compareWith(first!) {
      return 0
    } else if e > compareWith(last!) {
      return count
    }
    var lo = 0
    var hi = self.count - 1
    while lo <= hi {
      let mid = (lo + hi)/2
      let v = compareWith(self[mid])
      if e < v {
        lo = mid + 1
      } else if e > v {
        hi = mid - 1
      } else {
        return mid // found at position mid
      }
    }
    return lo
  }
  public func reversedIndex<T: Comparable>(for e: T, compareWith: (Element)->T) -> Int {
    guard count > 0 else { return 0 }
    if e > compareWith(first!) {
      return 0
    } else if e < compareWith(last!) {
      return count
    }
    var lo = 0
    var hi = self.count - 1
    while lo <= hi {
      let mid = (lo + hi)/2
      let v = compareWith(self[mid])
      if v < e {
        lo = mid + 1
      } else if v > e {
        hi = mid - 1
      } else {
        return mid // found at position mid
      }
    }
    return lo
  }
  public var any: Element {
    let index: Int = Int.random(max: count-1)
    return self[index]
  }
  public func shuffle() -> [Element] {
    var a = self
    var new = self
    let co = count
    let c = co - 1
    for i in 0..<a.count {
      let random = Double.random()
      let index = Int(random*Double(c-i))
      new[i] = a[index]
      a.remove(at: index)
      //print("[\(index)] \(String(a)) \(String(new))")
    }
    return new
  }
  public func shuffle(password: Int) -> [Element] {
    var a = self
    var new = self
    let co = count
    let c = co - 1
    for i in 0..<a.count {
      let random = Double.seed(password, i)
      let index = Int(random*Double(c-i))
      new[i] = a[index]
      a.remove(at: index)
      //print("[\(index)] \(String(a)) \(String(new))")
    }
    return new
  }
  public func restore(password: Int) -> [Element] {
    var new = [Element]()
    let co = count
    let c = co - 1
    for i in 0..<co {
      let b = c - i
      let random = Double.seed(password, i)
      let index = Int(random*Double(i))
      if index >= i {
        new.append(self[b])
      } else {
        new.insert(self[b], at: index)
      }
      //print("[\(index)] \(String(a)) \(String(new))")
    }
    return new
  }
  public func safe(_ index: Int) -> Element! {
    guard index >= 0 && index < count else { return nil }
    return self[index]
  }
  public func first(_ n: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    let end: Int = Swift.min(n, count)
    return self[0..<end]
  }
  public func first(_ n: Int, after: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    let start: Int = Swift.min(after, count - 1)
    let end: Int = Swift.min(after + n, count)
    return self[start..<end]
  }
  public func last(_ n: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    let start = Swift.max(count-n, 0)
    return self[start..<count]
  }
  public func last(_ n: Int, after: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    let start = Swift.max(count-n-after, 0)
    let end = Swift.max(0, count - after)
    return self[start..<end]
  }
  public func from(_ n: Int, max: Int) -> ArraySlice<Element> {
    guard count > n else { return [] }
    let end = Swift.min(count,n+max)
    return self[n..<end]
  }
  public func from(_ n: Int) -> ArraySlice<Element> {
    guard count > n else { return [] }
    return self[n...]
  }
  public func to(_ n: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    guard n >= 0 else { return [] }
    let to = Swift.min(count-1,n)
    return self[...to]
  }
  public func from(_ from: Int, to: Int) -> ArraySlice<Element> {
    guard !isEmpty else { return [] }
    guard from <= to else { return [] }
    guard to >= 0 else { return [] }
    let from = Swift.max(from,0)
    let to = Swift.min(to,count-1)
    return self[from...to]
  }
  public func right(_ index: Int) -> Element? {
    return safe(count-1-index)
  }
  public mutating func limit(_ count: Int) {
    guard self.count > count else { return }
    self = Array(self[0..<count])
  }
}
