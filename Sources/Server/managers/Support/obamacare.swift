//
//  obamacare.swift
//  Server
//
//  Created by Дмитрий Козлов on 4/26/17.
//
//

import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp



class Obamacare: ServerManager {
  var _anyActivity = false
  let locker = NSLock()
  var anyActivity: Bool {
    get {
      locker.lock()
      defer { locker.unlock() }
      return _anyActivity
    }
    set {
      locker.lock()
      defer { locker.unlock() }
      _anyActivity = newValue
    }
  }
  var autoClear = false
  
  override func start() {
    pthread {
      while true {
        sleep(300)
        self.run()
      }
    }
  }
  
  var previousLogs = [String]()
  func checkConnections(clear: Bool, logs: inout [String]) {
    if server.connections.count > 0 {
      let now = Time.now
      var count = 0
      server.connections.values.forEach {
        let secs = now - $0.lastActivity
        if secs > 300 {
          count += 1
          if autoClear {
            $0.disconnect()
          }
        }
      }
      if count > 0 {
        if autoClear {
          logs.append("disconnected \(count) inactive connections")
        } else {
          logs.append("found \(count) inactive connections")
        }
      }
    }
  }
  
  func run() {
    if anyActivity {
      anyActivity = false
      db.save()
    }
    var logs = [String]()
    
    checkConnections(clear: autoClear, logs: &logs)
    
    guard !logs.isEmpty else { return }
    guard logs != previousLogs else { return }
    previousLogs = logs
    logs.forEach { print("obamacare: \($0)") }
  }
}

extension Obamacare: TerminalCommands {
  func addCommands() {
    terminal.add(function: "obamacare autoclear") {
      print("autoclear is \(self.autoClear ? "enabled" : "disabled")")
    }
    terminal.add(function: "obamacare autoclear enable") {
      self.autoClear = true
      print("autoclear is \(self.autoClear ? "enabled" : "disabled")")
    }
    terminal.add(function: "obamacare autoclear disable") {
      self.autoClear = false
      print("autoclear is \(self.autoClear ? "enabled" : "disabled")")
    }
    terminal.add(function: "obamacare clear connections") {
      var logs = [String]()
      self.checkConnections(clear: true, logs: &logs)
      if logs.isEmpty {
        print("nothing to clear :(")
      } else {
        logs.forEach { print($0) }
      }
    }
    terminal.add(function: "obamacare clear") {
      var logs = [String]()
      self.checkConnections(clear: true, logs: &logs)
      if logs.isEmpty {
        print("nothing to clear :(")
      } else {
        logs.forEach { print($0) }
      }
    }
  }
}
