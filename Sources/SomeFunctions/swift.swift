
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Swift

/// returns class name in string format
/**
 let a = 10
 let b = className(a) // b = "Int"
 let c = className(b) // c = "String"
 */

public struct SomeSettings {
  
}


public func overrideRequired(file: String = #file, function: String = #function, line: Int = #line) -> Never {
  fatalError("""
    Class override required.
    file: \(file)
    line: \(line)
    function: \(function)
    """)
}

public func className(_ item: Any) -> String {
  return String(describing: item is Any.Type ? item : type(of: item))
}
public func setNil<T>(of value: inout T?, with: ()->(T)) {
  guard value == nil else { return }
  value = with()
}
public func unnil<T>(_ value: T?, _ error: Error) throws -> T {
  if let value = value {
    return value
  } else {
    throw error
  }
}

public func increment2d(_ x: inout Int, _ y: inout Int, _ width: Int) {
  x += 1
  if x >= width {
    x = 0
    y += 1
  }
}

public func ename(_ error: Error?) -> String {
  if let error = error {
    return String(describing: error)
  } else {
    return "nil"
  }
}

public protocol ComparableValue: Comparable {
  associatedtype Element: Comparable
  var comparableValue: Element { get }
}

extension ComparableValue {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue == rhs.comparableValue
  }
  public static func <(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue < rhs.comparableValue
  }
  public static func <=(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue <= rhs.comparableValue
  }
  public static func >=(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue >= rhs.comparableValue
  }
  public static func >(lhs: Self, rhs: Self) -> Bool {
    return lhs.comparableValue > rhs.comparableValue
  }
}


public class ActionLimiter {
  public var isIdle = true
  public var lastCommand: (()->())?
  public var time: Double
  public init(time: Double) {
    self.time = time
  }
  public func run(command: @escaping ()->()) {
    if isIdle {
      command()
      isIdle = false
//      if Thread.current.isMainThread {
//        wait(time, queue: .main, idle)
//      } else {
//        wait(time, queue: .global(), idle)
//      }
      wait(time, queue: .global(), idle)
    } else {
      lastCommand = command
    }
  }
  private func idle() {
    isIdle = true
    if let command = lastCommand {
      lastCommand = nil
      run(command: command)
    }
  }
}

public class Broadcaster<Owner> {
  private var listeners = Set<BroadcastListener<Owner>>()
  
  public var isEmpty: Bool {
    return listeners.isEmpty
  }
  let limiter: ActionLimiter
  public init(time: Double) {
    limiter = ActionLimiter(time: time)
  }
  
  @discardableResult
  public func subscribe(update: @escaping (Owner)->()) -> BroadcastListener<Owner> {
    let listener = BroadcastListener(update: update)
    listeners.insert(listener)
    return listener
  }
  @discardableResult
  public func subscribe(_ object: AnyObject, update: @escaping (Owner)->()) -> BroadcastObjectListener<Owner> {
    let listener = BroadcastObjectListener(object: object, update: update)
    listeners.insert(listener)
    return listener
  }
  public func unsubscribe(_ listener: BroadcastListener<Owner>) {
    listeners.remove(listener)
  }
  public func send(_ owner: Owner, limited: Bool = true) {
    if limited {
      limiter.run {
        self.send(owner, limited: false)
      }
    } else {
      for listener in listeners {
        if listener.isAvailable {
          listener.update(owner)
        } else {
          listeners.remove(listener)
        }
      }
    }
  }
}

// MARK:- unsorted
import Foundation

private let broadcasterLock = NSLock()
public class ThreadSafeBroadcaster<Owner> {
  private var listeners = Set<BroadcastListener<Owner>>()
  public var isEmpty: Bool {
    broadcasterLock.lock()
    defer { broadcasterLock.unlock() }
    return listeners.isEmpty
  }
  
  @discardableResult
  public func subscribe(update: @escaping (Owner)->()) -> BroadcastListener<Owner> {
    let listener = BroadcastListener(update: update)
    broadcasterLock.lock()
    listeners.insert(listener)
    broadcasterLock.unlock()
    return listener
  }
  
  @discardableResult
  public func subscribe(_ object: AnyObject, update: @escaping (Owner)->()) -> BroadcastObjectListener<Owner> {
    let listener = BroadcastObjectListener(object: object, update: update)
    broadcasterLock.lock()
    listeners.insert(listener)
    broadcasterLock.unlock()
    return listener
  }
  
  public func unsubscribe(_ listener: BroadcastListener<Owner>) {
    broadcasterLock.lock()
    listeners.remove(listener)
    broadcasterLock.unlock()
  }
  
  public func update(_ owner: Owner) {
    broadcasterLock.lock()
    for listener in listeners {
      if listener.isAvailable {
        listener.update(owner)
      } else {
        listeners.remove(listener)
      }
    }
    broadcasterLock.unlock()
  }
}

public class BroadcastListener<Owner>: Hashable {
  public var hashValue: Int { return ObjectIdentifier(self).hashValue }
  public static func ==(lhs: BroadcastListener, rhs: BroadcastListener) -> Bool {
    return lhs === rhs
  }
  
  var update: (Owner)->()
  var isAvailable: Bool { return true }
  init(update: @escaping (Owner)->()) {
    self.update = update
  }
}
public class BroadcastObjectListener<Owner>: BroadcastListener<Owner> {
  weak var object: AnyObject?
  override var isAvailable: Bool { return object != nil }
  init(object: AnyObject, update: @escaping (Owner)->()) {
    self.object = object
    super.init(update: update)
  }
}

public struct CompletionSubscribers {
  public var handlers = [()->()]()
  public var isCompleted = false
  public init() {}
  public mutating func subscribe(handler: @escaping ()->()) {
    if isCompleted {
      handler()
    } else {
      handlers.append(handler)
    }
  }
  public mutating func trigger() {
    guard !isCompleted else { return }
    isCompleted = true
    handlers.forEach { $0() }
    handlers.removeAll()
  }
}

open class SafeCompletionSubscribers {
  public var handlers = [()->()]()
  public var isCompleted = false
  
  public init() {}
  public func subscribe(handler: @escaping ()->()) {
    thread.lock()
    if isCompleted {
      thread.unlock()
      handler()
    } else {
      handlers.append(handler)
      thread.unlock()
    }
  }
  public func reset() {
    thread.lock()
    defer { thread.unlock() }
    isCompleted = false
  }
  public func trigger() {
    thread.lock()
    guard !isCompleted else {
      thread.unlock()
      return }
    isCompleted = true
    let handlers = self.handlers
    self.handlers.removeAll()
    thread.unlock()
    handlers.forEach { $0() }
  }
}


// MARK:- Not found error
public enum MainError: Error {
  case notFound
}
public var notFound: Error = MainError.notFound
