//
//  map.swift
//  Server
//
//  Created by Дмитрий Козлов on 6/12/17.
//
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class Map: ServerManager, CustomPath {
  let fileName = "map.db"
  var map = [[Set<Event>]](repeating: [Set<Event>](repeating: Set<Event>(), count: 360), count: 180)
  var subs = Set<Connection>()
  var optimizedStorage = true
  var displayed = Set<Event>()
  
  subscript(event: Event) -> Set<Event> {
    get {
      return map[Int(event.lat) + 90][Int(event.lon) + 180]
    } set {
      map[Int(event.lat) + 90][Int(event.lon) + 180] = newValue
    }
  }
  
  subscript(location: Location) -> Set<Event> {
    get {
      return map[location.ilat][location.ilon]
    } set {
      map[location.ilat][location.ilon] = newValue
    }
  }
  
  func save(data: DataWriter) throws {
    data.append(optimizedStorage)
    if optimizedStorage {
      let pointer = WriterPointer<Int>(data)
      var count = 0
      for i in 0..<180 {
        for j in 0..<360 {
          let events = map[i][j]
          guard events.count > 0 else { continue }
          count += 1
          data.append(i)
          data.append(j)
          data.append(events.ids)
        }
      }
      pointer.set(count)
    } else {
      for i in 0..<180 {
        for j in 0..<360 {
          let events = map[i][j]
          if events.isEmpty {
            data.append(0)
          } else {
            data.append(events.ids)
          }
        }
      }
    }
  }
  func load(data: DataReader) throws {
    var count = 0
    for event in events.events.reversed() where event.canBeDisplayedOnMap {
      count += 1
      displayed.insert(event)
      guard count < 500 else { break }
    }
    
    let optimized = try data.bool()
    if optimized {
      let count = try data.intFull()
      for _ in 0..<count {
        let i = try data.int()
        let j = try data.int()
        let ids = try data.intArray()
        map[i][j] = Set(ids.events)
      }
    } else {
      for i in 0..<180 {
        for j in 0..<360 {
          let ids: [Int] = try data.next()
          map[i][j] = Set(ids.events)
        }
      }
    }
  }
  
  func insert(event: Event) {
    self[event].insert(event)
  }
  func remove(event: Event) {
    self[event].remove(event)
  }
  func move(event: Event, from: Location) {
    self[from].remove(event)
    self[event].insert(event)
  }
  func move(event: Event, to: Location) {
    self[event].remove(event)
    self[to].insert(event)
  }
}

extension Map {
  func eventCreated(event: Event) {
    _insert(event: event)
  }
  func eventEnded(event: Event) {
    
  }
  func eventRemovedFromMap(event: Event) {
    _remove(event: event)
  }
  func eventAddedToMap(event: Event) {
    _insert(event: event)
  }
  func eventPrivacyChanged(event: Event) {
    if event.privacy >= .public {
      _insert(event: event)
    } else {
      _remove(event: event)
    }
  }
  func eventRemoved(event: Event) {
    _remove(event: event)
  }
  func eventBanned(event: Event) {
    _remove(event: event)
  }
  private func _insert(event: Event) {
    guard event.canBeDisplayedOnMap else { return }
    let (inserted, _) = displayed.insert(event)
    guard inserted else { return }
    serverEvents.mapInsert(event: event, to: subs)
  }
  private func _remove(event: Event) {
    guard displayed.remove(event) != nil else { return }
    serverEvents.mapRemove(event: event, to: subs)
  }
}

extension Map: TerminalCommands {
  func addCommands() {
    terminal.add(function: "map displayed") {
      thread.lock()
      let events = self.displayed.sorted { $0.id < $1.id }
      let count = events.count
      for event in events {
        print(event.id,event.name)
      }
      print("\n",count,"events")
      thread.unlock()
    }
  }
  
  
}

extension Event {
  fileprivate var canBeDisplayedOnMap: Bool {
    guard isOnMap else {
      return false }
    guard !isBanned else {
      return false }
    guard !isRemoved else {
      return false }
    guard privacy >= .public else {
      return false }
    return true
  }
  func nearEvents() -> Set<Event> {
    return map[self]
  }
}
