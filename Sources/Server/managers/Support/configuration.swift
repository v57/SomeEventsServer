//
//  configuration.swift
//  Server
//
//  Created by Дмитрий Козлов on 6/2/17.
//
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class Configuration {
  var dictionary = [String: String]()
  init() {
    load()
  }
  func load() {
    defer { save() }
    guard let data = "data/config.txt".dbURL.data else { return }
    let lines = data.string.lines
    for line in lines {
      let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !line.isEmpty else { continue }
      var params = line.components(separatedBy: "=")
      guard params.count > 1 else { continue }
      var key = params[0]
      var value: String
      if params.count > 2 {
        value = line.removeFirst(key.count+1)
      } else {
        value = params[1]
      }
      key = key.trimmingCharacters(in: .whitespacesAndNewlines)
      value = value.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !key.isEmpty else { continue }
      guard !value.isEmpty else { continue }
      guard value != "default" else { continue }
      dictionary[key] = value
    }
    if let ip = dictionary["ip"] {
      wifiIP = ip
    }
    if let portString = dictionary["port"] {
      if let portInt = Int(portString) {
        port = portInt
      }
    }
    if let portString = dictionary["httpPort"] {
      if let portInt = Int(portString) {
        httpPort = portInt
      }
    }
    if let path = dictionary["data path"] {
      dbPath = path
    }
    if let path = dictionary["content path"] {
      contentPath = path
    }
    if let path = dictionary["backup path"] {
      backupPath = path
    }
  }
  func save() {
    save(params: "ip, port, data path, content path, backup path")
  }
  func save(params: String) {
    var file = ""
    for param in params.components(separatedBy: ",") {
      let param = param.trimmingCharacters(in: .whitespacesAndNewlines)
      if param.isEmpty {
        file.addLine("")
      } else {
        file.addLine("\(param) = \(dictionary[param] ?? "default")")
      }
    }
    try? file.data.write(to: "data/config.txt".dbURL)
  }
}
