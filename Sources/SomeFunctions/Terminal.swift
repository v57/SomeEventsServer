//
//  Console.swift
//  Console
//
//  Created by Дмитрий Козлов on 16/08/16.
//  Copyright © 2016 LinO_dska. All rights reserved.
//
#if os(macOS) || os(Linux)
  import Foundation
  
  public let terminal = Console(name: "terminal")
  
  public extension String {
    public func cmd() {
      terminal.run(self)
    }
  }
  
  public enum ConsoleOverride {
    case weak, strong, weakMerge, strongMerge
  }
  
  open class Console: ConsoleCommand {
    public var printCommands = true
    public var printNewCommands = true
    public var printErrors = true
    public var commands = [String: ConsoleCommand]()
    public var mainCommand: ConsoleCommand?
    public var selected: Console?
    public weak var parent: Console?
    
    public var history = [String]()
    
    open func select(console: Console) {
      print("> \(console.name)")
      selected = console
      console.parent = self
    }
    open func select(command: String) {
      guard let cmd = commands[command] else {
        if printErrors {
          print("> console \(command) not found")
        }
        return
      }
      guard let console = cmd as? Console else {
        if printErrors {
          print("> \(command) is not a console")
        }
        return
      }
      select(console: console)
    }
    
    @discardableResult
    open func add(command: ConsoleCommand, override: ConsoleOverride = .strong) -> Bool {
      if let first = commands[command.name] {
        if override != .weak {
          let cmd = merge(command: first, with: command, override: override)
          commands[command.name] = cmd
          return true
        } else {
          return false
        }
      } else {
        commands[command.name] = command
        return true
      }
    }
    
    @discardableResult
    open func run(_ command: String) -> Bool {
      guard !command.isEmpty else { return false }
      history.append(command)
      if printCommands {
        print(command)
      }
      let array = command.components(separatedBy: " ")
      let cmd = Command(data: array)
      do {
        try execute(cmd)
      } catch CmdError.wrong {
        if printErrors {
          print("wrong command \"\(command)\"")
        }
        return false
      } catch {}
      return true
    }
    open override func execute(_ command: Command) throws {
      if let selected = selected {
        if command.data.count == 1 && command.data.first! == "close" {
          self.selected = nil
          print("> \(self.name)")
        } else {
          try selected.execute(command)
        }
      } else {
        guard let name = command.data.first, Int(name) == nil else {
          if let mainCommand = mainCommand {
            try mainCommand.execute(command)
          } else {
            let string = help(prefix: "> \(self.name) ", compressed: false)
            print("")
            print(string)
          }
          return }
        command.data.removeFirst()
        if command.data.count == 0 && (name == "help" || name == "?" || name == "??") {
          let compressed = name != "??"
          let string = help(prefix: "> ", compressed: compressed)
          print("")
          print(string)
        } else {
          if let cmd = self.commands[name] {
            try cmd.execute(command)
          } else {
            if let mainCommand = mainCommand {
              command.data.append(name)
              try mainCommand.execute(command)
            } else {
              throw CmdError.wrong
            }
          }
        }
      }
    }
    
    public func help(prefix: String = "", compressed: Bool) -> String {
      var result = ""
      if let main = mainCommand {
        if main.description.isEmpty {
          result.addLine("\(prefix)")
        } else {
          result.addLine("\(prefix)\(main.description)")
        }
      }
      //    print("\(prefix)\(name)")
      let sorted = commands.values.sorted { $0.name < $1.name }
      for command in sorted {
        let name = command.name
        if let command = command as? Console {
          let help = command.help(prefix: prefix + "\(name) ", compressed: compressed)
          if compressed && help.lines.count > 2 {
            result.addLine(">\(prefix)\(command.name) \(command.description)")
          } else {
            result.addLine(help)
          }
        } else {
          if command.description.isEmpty {
            result.addLine("\(prefix)\(name)")
          } else {
            result.addLine("\(prefix)\(name) \(command.description)")
          }
        }
      }
      if let console = parent?.selected, console === self {
        result.addLine("\(prefix)close")
      }
      return result
    }
    
    open func undo(_ command: String) -> Bool {
      guard !command.isEmpty else { return false }
      if printCommands {
        print("undo" + command)
      }
      var array = command.components(separatedBy: " ")
      let name = array.first!
      array.removeFirst()
      let cmd = Command(data: array)
      do {
        if let command = self.commands[name] {
          try command.undo(cmd)
        } else {
          throw CmdError.wrong
        }
      } catch CmdError.wrong {
        print("wrong command")
        return false
      } catch {}
      return true
    }
    
    @discardableResult
    open func add(advanced name: String, function: @escaping CmdAdvancedBlock) -> CmdAdvanced {
      var console = self
      let cmds = name.words
      let name = cmds.last!
      if cmds.count > 1 {
        for cmd in cmds.dropLast() {
          console = console.convert(command: cmd)
        }
      }
      
      let command = CmdAdvanced(name: name, function: function)
      console.add(command: command, override: .strong)
      return command
    }
    @discardableResult
    open func add(function name: String, function: @escaping ()throws->()) -> CmdSimple {
      var console = self
      let cmds = name.words
      let name = cmds.last!
      if cmds.count > 1 {
        for cmd in cmds.dropLast() {
          console = console.convert(command: cmd)
        }
      }
      
      let command = CmdSimple(name: name, function: function)
      console.add(command: command, override: .strong)
      return command
    }
    @discardableResult
    open func add(withParameters name: String, function: @escaping CmdParamsBlock) -> CmdParams {
      var console = self
      let cmds = name.words
      let name = cmds.last!
      if cmds.count > 1 {
        for cmd in cmds.dropLast() {
          console = console.convert(command: cmd)
        }
      }
      
      let command = CmdParams(name: name, function: function)
      console.add(command: command, override: .strong)
      return command
    }
    
    @discardableResult
    open func set(advanced name: String, function: @escaping CmdAdvancedBlock) -> CmdAdvanced {
      let command = CmdAdvanced(name: name, function: function)
      mainCommand = command
      return command
    }
    @discardableResult
    open func set(function name: String, function: @escaping ()->()) -> CmdSimple {
      let command = CmdSimple(name: name, function: function)
      mainCommand = command
      return command
    }
    @discardableResult
    open func set(withParameters name: String, function: @escaping CmdParamsBlock) -> CmdParams {
      let command = CmdParams(name: name, function: function)
      mainCommand = command
      return command
    }
    open func set(console: Console) {
      mainCommand = console
      console.parent = self
    }
    @discardableResult
    open func convert(command: String) -> Console {
      if let cmd = commands[command] {
        if let console = cmd as? Console {
          return console
        } else {
          let console = Console(name: command)
          console.mainCommand = cmd
          commands[command] = console
          return console
        }
      } else {
        let console = Console(name: command)
        commands[command] = console
        return console
      }
    }
    open func merge(with console: Console, override: ConsoleOverride) {
      switch override {
      case .weak: return
      case .strong:
        commands = console.commands
        if let main = console.mainCommand {
          mainCommand = main
        }
      case .strongMerge:
        if let main = console.mainCommand {
          mainCommand = main
        }
        for (id,command) in console.commands {
          commands[id] = command
        }
      case .weakMerge:
        if mainCommand == nil {
          mainCommand = console.mainCommand
        }
        for (id,command) in console.commands {
          if commands[id] == nil {
            commands[id] = command
          }
        }
      }
      description = console.description
    }
    private func merge(command first: ConsoleCommand, with second: ConsoleCommand, override: ConsoleOverride) -> ConsoleCommand {
      if let first = first as? Console {
        if let second = second as? Console {
          first.merge(with: second, override: override)
        } else {
          switch override {
          case .weak, .weakMerge:
            if first.mainCommand == nil {
              first.mainCommand = second
            }
          case .strong, .strongMerge:
            first.mainCommand = second
          }
        }
        return first
      } else if let second = second as? Console {
        if second.mainCommand != nil && (override == .weak || override == .weakMerge) {
          second.mainCommand = first
        }
        return second
      } else {
        return override == .weak || override == .weakMerge ? first : second
      }
    }
    
    public var listening = false
    public func listen() {
      printCommands = false
      listening = true
      var nilLine = 0
      while listening {
        sleep(1)
        guard let a = readLineFunction() else {
          nilLine += 1
          thread.lock {
            print("readLine nil: \(nilLine)")
          }
          continue
        }
        nilLine = 0
        guard !a.isEmpty else { continue }
        guard a != "exit" else { return }
        run(a)
      }
    }
    
    public var readLineFunction: ()->String? = readLine
  }
  
  @inline (__always)
  private func readLine() -> String? {
    return Swift.readLine()
  }
  
  func readLineFread() -> String? {
    var buf = [UInt8](repeating: 0, count: 100)
    let count = fread(&buf, 1, 32, stdin)
    if let string = String(bytes: buf[0..<count], encoding: .utf8) {
      return string.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
      var string = "\(Date()):"
      for byte in buf[0..<count] {
        string += " \(byte)"
      }
      exit(0)
    }
    return nil
  }
  
  public typealias CmdAdvancedBlock = (Command) throws -> ()
  public typealias CmdParamsBlock = (Command, Set<Character>) throws -> ()
  
  open class ConsoleCommand {
    open var name: String
    open var description: String = ""
    public init(name: String) {
      self.name = name
    }
    open func execute(_ command: Command) throws {
      
    }
    open func undo(_ command: Command) throws {
      
    }
  }
  
  open class CmdSimple: ConsoleCommand {
    open var function: () throws -> ()
    open var undo: (() -> ())?
    public init(name: String, function: @escaping ()throws->()) {
      self.function = function
      super.init(name: name)
    }
    open override func execute(_ command: Command) throws {
      try function()
    }
    open override func undo(_ command: Command) throws {
      undo?()
    }
  }
  
  open class CmdAdvanced: ConsoleCommand {
    open var function: CmdAdvancedBlock
    open var undo: CmdAdvancedBlock?
    public init(name: String, function: @escaping CmdAdvancedBlock) {
      self.function = function
      super.init(name: name)
    }
    open override func execute(_ command: Command) throws {
      try function(command)
    }
    open override func undo(_ command: Command) throws {
      try undo?(command)
    }
  }
  
  open class CmdParams: ConsoleCommand {
    open var function: CmdParamsBlock
    open var undo: CmdParamsBlock?
    public init(name: String, function: @escaping CmdParamsBlock) {
      self.function = function
      super.init(name: name)
    }
    open override func execute(_ command: Command) throws {
      let params = getParams(command)
      try function(command, params)
    }
    open override func undo(_ command: Command) throws {
      let params = getParams(command)
      try undo?(command, params)
    }
    func getParams(_ command: Command) -> Set<Character> {
      if let first = command.data.first , first.hasPrefix("-") {
        command.data.removeFirst()
        let first = first.substring(from: first.index(first.startIndex, offsetBy: 1))
        return Set(first)
      } else {
        return Set<Character>()
      }
    }
  }
  
  public enum CmdError: Error {
    case wrong, noprint
  }
  
  public class Command {
    public var data: [String]
    init(data: [String]) {
      self.data = data
    }
    public var isEmpty: Bool { return data.isEmpty }
    public var error: Error { return CmdError.wrong }
    public func text() throws -> String {
      guard data.count > 0 else { throw CmdError.wrong }
      var text = String(describing: data[0])
      if data.count > 1 {
        for word in data[1..<data.count] {
          text += " "
          text += String(describing: word)
        }
      }
      return text
    }
    public func string() throws -> String {
      guard data.count > 0 else { throw CmdError.wrong }
      return String(describing: data.removeFirst())
    }
    public func int() throws -> Int {
      guard data.count > 0 else { throw CmdError.wrong }
      guard let int = Int(String(describing: data.removeFirst())) else { throw CmdError.wrong }
      return int
    }
    public func url() throws -> URL {
      let s = try string()
      guard let url = URL(string: s) else { throw CmdError.wrong }
      return url
    }
    public func path() throws -> URL {
      let s = try string()
      let url = URL(fileURLWithPath: s)
      return url
    }
  }
  
  public extension Array where Element: ExpressibleByStringLiteral {
    public func text() throws -> String {
      guard count > 0 else { throw CmdError.wrong }
      var text = String(describing: self[0])
      if count > 1 {
        for word in self[1..<count] {
          text += " "
          text += String(describing: word)
        }
      }
      return text
    }
    public mutating func word() throws -> String {
      guard count > 0 else { throw CmdError.wrong }
      return String(describing: removeFirst())
    }
    public mutating func int() throws -> Int {
      guard count > 0 else { throw CmdError.wrong }
      guard let int = Int(String(describing: removeFirst())) else { throw CmdError.wrong }
      return int
    }
    public mutating func url() throws -> String {
      guard count > 0 else { throw CmdError.wrong }
      return String(describing: removeFirst())
    }
    public mutating func path() throws -> String {
      guard count > 0 else { throw CmdError.wrong }
      return String(describing: removeFirst())
    }
  }
  
#endif
