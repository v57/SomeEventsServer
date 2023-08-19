//
//  list.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 2/11/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData

class EventList: ServerManager, CustomPath {
  let fileName = "eventList.db"
  private(set) var firstOnline: Time = 0
  private var _online = [Event]()
  var online: [Event] {
    updateOnline()
    return _online
  }
  
  private(set) var newest = [Event]()
  
  private var firstPlanned: Time = 0
  private var _planned = [Event]()
  var planned: [Event] {
    updatePlanned()
    return _planned
  }
  
  func eventCreated(event: Event) {
    let now = Time.now
    if event.endTime < now {
      event.options.insert(.online)
      _online.append(event)
      firstOnline = min(event.endTime, firstOnline)
    }
    map.insert(event: event)
  }
  
  func updateOnline() {
    let now = Time.now
    guard firstOnline < now else { return }
    firstOnline = .max
    var removed = [Int]()
    for (i,event) in _online.enumerated() {
      if event.endTime <= now {
        removed.append(i-removed.count)
      } else {
        firstOnline = min(firstOnline, event.endTime)
      }
    }
    guard !removed.isEmpty else { return }
    for i in removed {
      _online.remove(at: i)
    }
    self.removed(online: removed.events)
  }
  
  func insert(online event: Event) {
    guard !event.isOnline else { return }
    event.isOnline = true
    _online.append(event)
  }
  func remove(online event: Event) {
    guard let index = _online.index(of: event) else { return }
    _online.remove(at: index)
    removed(online: [event])
  }
  func removed(online events: [Event]) {
    for event in events {
      event.isOnline = false
    }
  }
  func added(online events: [Event]) {
    for event in events {
      event.isOnline = true
    }
  }
  
  func updateNewest() {
    
  }
  
  func updatePlanned() {
    let now = Time.now
    guard firstPlanned < now else { return }
    var ids = [Int]()
    firstPlanned = .max
    for (i,event) in _planned.enumerated() {
      if event.startTime < now {
        ids.append(i-ids.count)
      } else {
        firstPlanned = min(event.startTime,firstPlanned)
      }
    }
    for i in ids {
      _planned.remove(at: i)
    }
  }
  
  func load(data: DataReader) throws {
    firstOnline = try data.time()
    _online = try data.intArray().events
    newest = try data.intArray().events
    firstPlanned = try data.time()
    _planned = try data.intArray().events
  }
  func save(data: DataWriter) throws {
    data.append(firstOnline)
    data.append(_online.ids)
    data.append(newest.ids)
    data.append(firstPlanned)
    data.append(_planned.ids)
  }
}
























