//
//  pthread.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 08/06/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation

/// run @block in main thread
public func mainThread(_ block: @escaping ()->()) {
  if Thread.current.isMainThread {
    block()
  } else {
    DispatchQueue.main.async(execute: block)
  }
}

/// run @block in background thread
public func backgroundThread(_ block: @escaping ()->()) {
  DispatchQueue.global(qos: .background).async(execute: block)
}

extension Time {
  public func wait(_ block: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(self), execute: block)
  }
}

/// wait @time seconds, then run @block in main thread
public func wait(_ time: Double, _ block: @escaping ()->()) {
  DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time, execute: block)
}

/// wait @time seconds, then run @block in main thread
public func wait(_ time: Double, queue: DispatchQueue, _ block: @escaping ()->()) {
  queue.asyncAfter(deadline: DispatchTime.now() + time, execute: block)
}

/// run @block in new thread
public func newThread(_ block: @escaping ()->()) {
  let queue = DispatchQueue.global(qos: .default)
  queue.async(execute: block)
}

/// block current thread untill unblock() returns false
public func blockThread(untill unblock: ()->Bool) {
  while !unblock() {
    sleep(1)
  }
}
/*
extension pthread_mutex_t {
  public init() {
    __sig = 0
    __opaque = (0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0)
  }
}

extension pthread_rwlock_t {
  
  public init() {
    __sig = 0
    __opaque = (0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0)
  }
}
*/
public func locked(_ mutex: UnsafeMutablePointer<pthread_mutex_t>,f: ()->()) {
  pthread_mutex_lock(mutex)
  f()
  pthread_mutex_unlock(mutex)
}

public func pthread(block: @escaping ()->()) {
  if #available(OSX 10.12, *) {
    Thread(block: block).start()
  } else {
    OperationQueue().addOperation(block)
  }
}

//public func pthread_create(block: @escaping ()->()) throws -> Strand {
//  return try Strand(closure: block)
//}

public func namedThread(_ name: String, block: @escaping ()->()) {
  let queue = DispatchQueue(label: name)
  queue.async(execute: block)
}

extension NSLock {
  public func lock(_ execute: ()->()) {
    lock()
    execute()
    unlock()
  }
}

public class SafeLocker {
  var isLocked: Bool = false
  var locker: NSLock
  init(locker: NSLock) {
    self.locker = locker
  }
  
  public func lock() {
    isLocked = true
    locker.lock()
  }
  public func unlock() {
    isLocked = false
    locker.unlock()
  }
  
  deinit {
    if isLocked {
      locker.unlock()
    }
  }
}

public let thread = SomeThread(name: "somethread")
public class SomeThread {
  private let queue: DispatchQueue
  public var locker: NSLock
  public var safeLocker: SafeLocker {
    return SafeLocker(locker: locker)
  }
  public init(name: String) {
    queue = DispatchQueue(label: name, attributes: .concurrent)
    locker = NSLock()
  }
  
  open func async(block: @escaping ()->()) {
    queue.async {
      self.locker.lock()
      block()
      self.locker.unlock()
    }
  }
  
  open func named(_ name: String, block: @escaping ()->()) {
    DispatchQueue(label: name).async(execute: block)
  }
  
  open func main(block: @escaping ()->()) {
    DispatchQueue.main.async(execute: block)
  }
  
  open func background(block: @escaping ()->()) {
    DispatchQueue.global(qos: .background).async(execute: block)
  }
  
  open func new(block: @escaping ()->()) {
    DispatchQueue.global(qos: .default).async(execute: block)
  }
  
  open func readWrite(execute: ()->()) {
    queue.sync(execute: execute)
  }
  open func write(execute: @escaping ()->()) {
    queue.async(flags: .barrier, execute: execute)
  }
  open func lock() {
    locker.lock()
  }
  open func unlock() {
    locker.unlock()
  }
  open func lock(block: ()throws->()) rethrows {
    locker.lock()
    defer { locker.unlock() }
    try block()
  }
  
  // deadlock debugger
  
  //  open func lock(file: String = #file, function: String = #function, line: Int = #line) {
  //    print("locking thread")
  //    locker.lock()
  //    print("\(file) \(function) \(line)")
  //    print("thread locked")
  //  }
  //  open func unlock() {
  //    locker.unlock()
  //    print("thread unlocked")
  //  }
  //  open func lock(file: String = #file, function: String = #function, line: Int = #line, block: ()->()) {
  //    print("locking thread")
  //    locker.lock()
  //    print("\(file) \(function) \(line)")
  //    print("thread locked")
  //    block()
  //    locker.unlock()
  //    print("thread unlocked")
  //  }
}

extension DispatchQueue {
  public func readWrite(execute: ()->()) {
    sync(execute: execute)
  }
  public func write(execute: @escaping ()->()) {
    async(flags: .barrier, execute: execute)
  }
}
