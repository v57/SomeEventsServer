//
//  scripts.swift
//  Server
//
//  Created by Дмитрий Козлов on 2/22/17.
//
//

import Foundation
import SomeFunctions
import SomeData

private class ScriptEditor {
  let console: Console
  let name: String
  let url: FileURL
  init(name: String) {
    self.name = name
    url = scripts.url(name: name)
    console = Console(name: "script")
    console.printErrors = false
    console.add(function: "save") { [unowned self] in
      try self.save()
    }
  }
  func save() throws {
    let history = console.history.dropLast()
    var string = ""
    history.forEach { string.addLine($0) }
    try string.write(to: url.url, atomically: true, encoding: .utf8)
    console.parent?.run("close")
  }
  func load() {
    guard let commands = url.data?.string, !commands.isEmpty else { return }
    console.history = commands.lines
    console.history.forEach {
      print($0)
    }
    print("")
  }
}

class Scripts: ServerManager {
  let format = "txt"
  let startScript = "start"
  let loadingScript = "loading"
  let loadedScript = "loaded"
  
  func url(name: String) -> FileURL {
    var name = name
    cut(name: &name)
    return "scripts/\(name).\(format)".dbURL
  }
  func cut(name: inout String) {
    if name.last(format.count) == format {
      name = name.removeLast(format.count)
    }
  }
  
  private var editor: ScriptEditor?
  override func start() {
    "scripts".dbURL.create()
    "scripts/\(loadingScript).\(format)".dbURL.create()
    "scripts/\(loadedScript).\(format)".dbURL.create()
    "scripts/\(startScript).\(format)".dbURL.create()
    
    terminal.add(advanced: "script") { command in
      var name = try command.text()
      self.cut(name: &name)
      self.run(script: name)
    }.description = "<scriptName: String> # runs script"
    terminal.add(advanced: "script create") { command in
      let name = try command.text()
      let editor = ScriptEditor(name: name)
      terminal.select(console: editor.console)
      self.editor = editor
      
      print("save / close")
    }
    terminal.add(advanced: "script read") { command in
      let name = try command.text()
      if let string = self.url(name: name).data?.string {
        print(string)
      } else {
        print("script not found")
      }
    }
    terminal.add(advanced: "script edit") { command in
      let name = try command.text()
      let editor = ScriptEditor(name: name)
      editor.load()
      terminal.select(console: editor.console)
      self.editor = editor
      print("save / close")
    }
    terminal.add(advanced: "script list") { command in
      let scripts = "scripts".dbURL.content.filter { $0.extension == self.format }
      print("")
      scripts.forEach { print($0.name) }
      if scripts.isEmpty {
        print("no scripts")
      }
    }
    
    // сохраняем список команд в scripts/commands.txt
    let help = terminal.help(compressed: false)
    try? help.data.write(to: "scripts/commands.txt".dbURL)
  }
  
  func loading() {
    // запускаем скирпт loading.txt
    run(script: loadingScript)
  }
  
  func loaded() {
    // запускаем скирпт loaded.txt
    run(script: loadedScript)
  }
  
  func started() {
    // запускаем скирпт start.txt
    run(script: startScript)
  }
  
  func run(script: String) {
    guard script != "commands" else {
      print("script name cannot be \"commands\"")
      return }
    let url = "scripts/\(script).\(format)".dbURL
    guard let file = url.data?.string else {
      print("script not found")
      return }
    for command in file.lines where !command.isEmpty {
      switch command.first(2) {
      case "# ": break
      case "@ ": print(command.removeFirst(2))
      default: terminal.run(command)
      }
    }
  }
}
