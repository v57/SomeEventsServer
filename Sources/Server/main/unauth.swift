//
//  server-unauth.swift
//  Server
//
//  Created by Дмитрий Козлов on 2/23/17.
//
//

import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp
import SomeBridge

extension API {
  func unauth(commands: inout [cmd: ServerFunction]) {
    commands[.auth] = login
    commands[.signup] = signup
  }
}

private func login(connection: Connection, request: DataReader) throws {
  let id = try request.int()
  let password = try request.uint64()
  let user = try users.login(id: id, password: password)
  print("loginned \(user.id) \(user.password)")
  connection.set(user: user)
  let data = connection.response(.ok)
  
  thread.lock()
  let isMainLoaded = try request.bool()
  
  let mainVersion = try request.uint16()
  let shouldUpdateMain = mainVersion != user.mainVersion || !isMainLoaded
  data.append(shouldUpdateMain)
  if shouldUpdateMain {
    user.write(main: data)
  }
  
  let publicVersion = try request.uint16()
  let shouldUpdatePublic = publicVersion != user.publicProfileVersion || !isMainLoaded
  data.append(shouldUpdatePublic)
  if shouldUpdatePublic {
    data.append(user.publicProfileVersion)
    user.events.eventMain(data: data)
  }
  
  
  let privateVerison = try request.int()
  let shouldUpdatePrivate = privateVerison != user.privateProfileVersion || !isMainLoaded
  data.append(shouldUpdatePrivate)
  if shouldUpdatePrivate {
    data.append(user.privateOptions)
    data.append(user.privateProfileVersion)
    data.append(user.friends)
    data.append(user.outcoming)
    data.append(user.incoming)
    data.append(user.subscribers.count)
    data.append(user.subscriptions)
    data.append(user.favorite)
  }
  
  if user.isModerator {
    data.append(reports.count)
    data.append(reports.uncheckedCount)
  }
  thread.unlock()
  
  connection.tsend(data)
}

private func signup(connection: Connection, data: DataReader) throws {
  let name = try data.string()
  print(" signup")
  print(" name \(name)")
  
  thread.lock()
  let user = users.create(name: name)
  thread.unlock()
  
  print("  created user with id: \(user.id) password: \(user.password)")
  let d = connection.response(.ok)
  d.append(user.id)
  d.append(user.password)
  connection.tsend(d)
  
  thread.lock()
  connection.set(user: user)
  thread.unlock()
}
