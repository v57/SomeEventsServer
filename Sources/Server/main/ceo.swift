//
//  ceo.swift
//  Server
//
//  Created by Дмитрий Козлов on 12/17/17.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

protocol ApiManager: class {
  
}
protocol AuthCommands: ApiManager {
  func auth(commands: inout [cmd: ServerFunction])
}
protocol FileCommands: ApiManager {
  func files(commands: inout [cmd: ServerFunction])
}
protocol UnauthCommands: ApiManager {
  func unauth(commands: inout [cmd: ServerFunction])
}
protocol AdminCommands: ApiManager {
  func admin(commands: inout [cmd: ServerFunction])
}
protocol ModeratorCommands: ApiManager {
  func moderator(commands: inout [cmd: ServerFunction])
}
protocol CounterManager: ApiManager {
  var counter: Counter<ID> { get set }
}
class ServerManager: Manager {
  init() {
    ceo.append(self)
  }
  func start() {
    
  }
}
class Ceo: SomeCeo {
  override func url(for path: String) -> FileURL {
    return "data/\(path)".dbURL
  }
  override func presave(manager: Saveable, data: DataWriter) {
    super.presave(manager: manager, data: data)
    if let manager = manager as? CounterManager {
      data.append(manager.counter)
    }
  }
  override func preload(manager: Saveable, data: DataReader) throws {
    try super.preload(manager: manager, data: data)
    if let manager = manager as? CounterManager {
      try manager.counter = data.next()
    }
  }
  override func setup(data: DataReader) {
    data.safeLimits = .max
  }
  override func setup(data: DataWriter) {
    
  }
}
