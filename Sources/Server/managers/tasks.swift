//
//  tasks.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 23/07/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

/*
class Tasks: ServerManager, CustomPath {
  let fileName = "tasks.db"
  var tasks = [Task]()
  subscript(index: Int) -> Task? {
    guard index >= 0 && index < tasks.count else { return nil }
    return tasks[index]
  }
  
  override func start() {
    let console = Console(name: "task")
    console.add(function: "create") {
      let task = Task()
      task.created = Time.now
      self.tasks.append(task)
      let id = self.tasks.count - 1
      print("created task with id \(id)")
    }
    console.add(advanced: "remove") { command in
      let id = try command.taskid()
      self.tasks.remove(at: id)
    }.description = "<id: Int>"
    console.add(function: "list") {
      for (id,task) in self.tasks.enumerated() {
        print("\(id) - \(task.name)")
      }
    }
    console.add(advanced: "info") { command in
      let task = try command.task()
      
      print("name: \(task.name)")
      print("description: \(task.description)")
      print("progress: \(task.progress)%")
      print("likes: \(task.likes.count)")
      print("created: \(task.created.date)")
    }.description = "<id: Int>"
    console.add(advanced: "setProgress") { command in
      let task = try command.task()
      var progress = try command.int()
      progress = max(progress,0)
      progress = min(progress,100)
      task.progress = progress
    }.description = "<id: Int> <progress: 0-100>"
    console.add(advanced: "setName") { command in
      let task = try command.task()
      task.name = try command.string()
    }.description = "<id: Int> <name: String>"
    console.add(advanced: "setDescription") { command in
      let task = try command.task()
      task.description = try command.string()
    }.description = "<id: Int> <description: String>"
    console.add(advanced: "completed") { command in
      let task = try command.task()
      task.progress = 100
    }.description = "<id: Int>"
    console.add(advanced: "comment") { command in
      let task = try command.task()
      let text = try command.text()
      let comment = Message(from: 0, time: Time.now, body: text)
      task.add(comment: comment)
    }.description = "<id: Int> <text: String>"
    console.add(advanced: "read") { command in
      let task = try command.task()
      for comment in task.comments {
        print("\(comment.time.timeFormat)) \(comment)")
      }
    }.description = "<id: Int>"
    terminal.add(command: console, override: .strong)
  }
  
  func load(data: DataReader) throws {
    let count = try data.int()
    for _ in 0..<count {
      let task = Task()
      try task.load(data)
      tasks.append(task)
    }
  }
  func save(data: DataWriter) throws {
    data.append(tasks.count)
    for task in tasks {
      task.save(data)
    }
  }
}

class TaskList {
  var ids = Set<Task>()
  var cached: [Task]?
  var sorted: [Task] {
    if let cached = cached {
      return cached
    } else {
      let sorted = tasks.tasks.sorted(by: { $0.likes.count > $1.likes.count })
        return sorted
    }
    
  }
  func insert(task: Task) {
    
  }
   func remove(task: Task) {}
}

class Task: Hashable {
  private static var ids = Counter<ID>()
  static var id: ID { return ids.next() }
  var hashValue: Int { return id.hashValue }
    static func ==(l:Task,r:Task)->Bool { return l.id==r.id }
  
  var name = ""
  var description = ""
  var progress = 0
  var likes = Set<Int>()
  var comments = [Message]()
  var created: Time = 0
  var id: Int = 0
  
  enum Status: UInt8 {
    case waiting, reviewed, accepted, declined, completed, nextUpdate
  }
  
  func add(comment: Message) {
    comments.append(comment)
  }
  
  func like(_ id: Int) {
    likes.insert(id)
  }
  func liked(_ id: Int) -> Bool {
    return likes.contains(id)
  }
  
  func save(_ data: DataWriter) {
    data.append(id)
    data.append(name)
    data.append(description)
    data.append(progress)
    data.append(likes)
    data.append(created)
    data.append(messages: comments)
  }
  func load(_ data: DataReader) throws {
    id = try data.int()
    name = try data.string()
    description = try data.string()
    progress = try data.int()
    likes = try data.next()
    created = try data.next()
    comments = try! data.messages()
  }
}



private extension Command {
  @discardableResult
  func task() throws -> Task {
    let id = try int()
    guard let task = tasks[id] else {
      print("task \(id) not found")
      throw CmdError.noprint
    }
    return task
  }
  func taskid() throws -> Int {
    let id = try int()
    guard tasks[id] != nil else {
      print("task \(id) not found")
      throw CmdError.noprint
    }
    return id
  }
}
*/
