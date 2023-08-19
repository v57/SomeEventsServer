//
//  debug.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 2/9/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions

class Debug: ServerManager {
  override func start() {
    let console = Console(name: "debug")
    console.add(function: "print") {
      db.printAll()
    }
    console.add(function: "cpu") {
      cpuMonitor.debug()
    }
    console.add(function: "svcmd") {
      db.printCMD()
    }.description = "# prints list of server commands"
    console.add(function: "clcmd") {
      db.printSUBCMD()
    }.description = "# prints list of client commands"
    terminal.add(command: console)
  }
}
