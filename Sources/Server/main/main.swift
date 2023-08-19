//
//  main.swift
//  faggot server
//
//  Created by Дмитрий Козлов on 26/01/16.
//  Copyright © 2016 anus. All rights reserved.
//
import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp
import SomeBridge

SomeSettings.debugCeo = false
SomeSettings.debugFileURL = false
SomeSettings.debugTcp = false
corrupted = Response.requestCorrupted

let initTimer = CPUTimer(name: "init")
initTimer.resume()

let ceo = Ceo()
let config = Configuration()

var db = DB()
var server = Server(port: address.port)
//let localServer = TCPServer(ip: localhost, port: 1488)

let http = HTTPManager()
let cpuMonitor = CPUMonitor()
let versions = Versions()

// before events

let users = Users.shared
// after users
let events = Events.shared
let chats = Chats()
let moderators = Moderators()
let admins = Admins()
// after users, events
let map = Map()
let list = EventList()
let bots = Bots()

// any position
let keyManager = KeyManager()
//let tasks = Tasks()
let monitor = Monitor()
let debug = Debug()
let pushManager = PushManager()
let reports = ReportsManager()

// last one
let scripts = Scripts()
let obamacare = Obamacare()
let trash = Trash()
let api = API()


func start() {
  scripts.loading()
  db.start()
  scripts.loaded()
  try? server.start()
  scripts.started()
}

func restart() {
  guard server.connections.count == 0 else {
    print("pls close all connections")
    return
  }
  server.close()
  server = Server(port: address.port)
  start()
}

func restartApp() {
  db.save()
  server.close()
  terminal.listening = false
  let processIdentifier = String(ProcessInfo.processInfo.processIdentifier)
  if let path = Bundle.main.executablePath {
    _ = Process.launchedProcess(launchPath: path, arguments: [processIdentifier])
    exit(9)
  }
}

runLocalServer()
newThread {
  try? http.start()
}
addCommands()
start()

initTimer.pause()
cpuMonitor.debug()

test()

extension Character {
  var unicodeScalar: Unicode.Scalar {
    return Unicode.Scalar(unicodeScalars.map { $0.value }.reduce(0, +))!
  }
  var unicodeScalar2: Unicode.Scalar {
    let scalars = unicodeScalars
    return Unicode.Scalar(scalars[scalars.startIndex].value)!
  }
}

func readLineFileHandle() -> String? {
  let keyboard = FileHandle.standardInput
  let data = keyboard.availableData
  guard let inputData = String(data: data, encoding: .utf8) else { return "" }
  // фильтруем стрелочки
  let filtered = inputData.filter { $0.unicodeScalar.value < 60000 }
  return String(filtered).trimmingCharacters(in: .whitespacesAndNewlines)
}

//for i in 0..<5000000 {
//  users.create(name: "Ivan")
//  if i % 10000 == 0 {
//    print(i,"/","5000000")
//  }
//}
//print("gotovo", terminator: "")

terminal.readLineFunction = readLineFileHandle
terminal.listen()
RunLoop.main.run()

