//
//  lagometer.swift
//  Server
//
//  Created by Дмитрий Козлов on 4/11/17.
//
//

import Foundation
import SomeFunctions

class CPUTimer {
  private let name: String
  private var started = 0
  private var time = 0
  private var isRunning = false
  init(name: String) {
    self.name = name
  }
  func resume() {
    guard !isRunning else { return }
    isRunning = true
    started = timeval.now.usecs
  }
  func pause() {
    guard isRunning else { return }
    isRunning = false
    time += timeval.now.usecs - started
  }
  deinit {
    pause()
    if cpuMonitor.values[name] != nil {
      cpuMonitor.values[name]! += time
    } else {
      cpuMonitor.values[name] = time
    }
  }
}

class CPUMonitor {
  var values = [String: Int]()
  func debug() {
    guard values.count > 0 else {
      print("empty")
      return
    }
    let sorted = values.sorted { $0.value > $1.value }
    for (key, value) in sorted {
      print("\(key): \(value)")
    }
  }
}
