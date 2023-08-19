//
//  progress.swift
//  SomeFunctions
//
//  Created by Дмитрий Козлов on 3/3/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

public protocol ProgressProtocol: class {
  var total: Int64 { get }
  var completed: Int64 { set get }
  var isPaused: Bool { get }
  var isCancelled: Bool { get }
  var isCompleted: Bool { get }
}

open class CustomProgress: ProgressProtocol {
  public var total: Int64 = 0
  public var completed: Int64 = 0
  public var isPaused: Bool = false
  public var isCancelled: Bool = false
  public var isCompleted: Bool {
    return total == completed
  }
  public init() {}
}

extension ProgressProtocol {
  public var isCancelled: Bool { return false }
  public var isPaused: Bool { return false }
  public var isCompleted: Bool {
    return completed >= total
  }
}

extension Progress: ProgressProtocol {
  public var total: Int64 {
    get {
      return totalUnitCount
    } set {
      totalUnitCount = newValue
    }
  }
  public var completed: Int64 {
    get {
      return completedUnitCount
    }
    set {
      completedUnitCount = newValue
    }
  }
  public var isCompleted: Bool {
    return total == completed
  }
}

extension CustomProgress {
  public static func test() -> CustomProgress {
    let progress = CustomProgress()
    progress.total = 1024
    
    wait(.random(min: 0.5, max: 2.0)) {
      var value: Double = 0.0
      var time: Double = 0.0
      while value < 1.0 {
        let rt: Double = .random(min: 0.03, max: 0.1)
        let rv: Double = .random(min: 0.001, max: 0.03)
        time += rt
        value += rv
        let v = value
//        if 1% {
//          if 1% {
//            wait(time) {
//              progress.cancel()
//            }
//            return
//          }
//        }
        wait(time) {
          progress.completed = Int64(v * Double(progress.total))
        }
      }
      wait(time) {
        progress.completed = progress.total
      }
    }
    return progress
  }
}
