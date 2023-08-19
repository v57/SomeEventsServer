//
//  events.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 12/8/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData

private var maxEvents = 1000
private var eventsPack = 1000

class Events: ServerManager, CustomPath {
  var version: Int = 2
  let fileName = "events.db"
  static let shared = Events()
  var events = [Event]()
  var count: Int {
    return events.count
  }
  var capacity: Int {
    return events.capacity
  }
  
//  func set(event: Event) {
//    events[event.id] = event
//  }
  
  /*
  func create(event: Event, user: User, notify: Bool) {
    if count == events.count {
      events.append(contentsOf: [Event?](repeating: nil, count: eventsPack))
      print("increased events limit to \(events.count)")
    }
    
    event.createDirectories()
    
    events[event.id] = event
    user.events.insert(event.id)
    user.publicProfileVersion.increment()
    count += 1
    if notify {
      serverEvents.eventCreated(event: event, by: user)
    }
    list.eventCreated(event: event)
  }
   */
  
  func create(event: Event, user: User, notify: Bool) {
    event.createDirectories()
    
    append(event: event)
    user.events.insert(event.id)
    user.publicProfileVersion.increment()
    if notify {
      serverEvents.eventCreated(event: event, by: user)
    }
    list.eventCreated(event: event)
  }
  
  subscript(id: Int) -> Event! {
    guard id >= 0 && id < events.count else { return nil }
    return events[id]
  }
  
//  func updateDirectories() {
//    for event in events {
//      guard let event = event else { continue }
//      "content/events/\(event.id)".contentURL.create()
//      "content/events/\(event.id)/previews".contentURL.create()
//      "temp/events/\(event.id)".contentURL.create()
//      "temp/events/\(event.id)/previews".contentURL.create()
//      for content in event.content {
//        if let content = content as? PhotoContent {
//          try? content.oldURL.clone(to: content.url(event: event))
//          try? content.oldPreviews.clone(to: content.previewURL(event: event))
//        } else if let content = content as? VideoContent {
//          try? content.oldURL.clone(to: content.url(event: event))
//          try? content.oldPreviews.clone(to: content.previewURL(event: event))
//        }
//      }
//    }
//  }
  
  
  func printAll() {
    print("------------")
    print("Events")
    print(" count:  \(count)/\(capacity)")
    print(" online: \(list.online.count)")
//    print(" photos: \(photosCount)/\(maxPhotos)")
//    print(" videos: \(videosCount)/\(maxVideos)")
  }
  
  func printIds() {
    for event in events {
      print("\(event.id) - \(event.name)")
    }
  }
  func calculateContentSize() {
    var photos = 0
    var photosSize: UInt64 = 0
    var videos = 0
    var videosSize: UInt64 = 0
    for event in events {
      for c in event.content.values {
        if let photo = c as? PhotoContent {
          photos += 1
          photosSize += photo.size
        } else if let video = c as? VideoContent {
          videos += 1
          videosSize += video.size
        }
      }
    }
    print("photos: \(photos), size: \(photosSize.bytesString)")
    print("videos: \(videos), size: \(videosSize.bytesString)")
  }
  
  /*
  func load(data: DataReader) throws {
    // users
    let count = try data.int()
    users.reserveCapacity(count)
    reserve()
    for _ in 0..<count {
      let user = User()
      try user.load(data: data)
      append(user: user)
    }
    print("loaded \(count) users")
  }
  func save(data: DataWriter) throws {
    print("saving users")
    data.append(count)
    for user in self.users {
      user.save(data: data)
    }
  }
 */
  
  func load(data: DataReader) throws {
    Event.version = try data.int()
    if version < 2 {
      maxEvents = try data.int()
    }
    
    let count = try data.int()
    events = []
    events.reserveCapacity(count)
    for _ in 0..<count {
      let event = try Event(data: data)
//      if event.lat != 0 || event.lon != 0 {
//        event.options[.onMap] = true
//      }
      append(event: event)
    }
    print("loaded \(count) events")
  }
  func save(data: DataWriter) throws {
    data.append(Event.version)
//    data.append(self.events.count)
    data.append(count)
    for event in self.events {
      event.save(data: data)
    }
  }
}

private extension Events {
  private var eventsPack: Int { return 1000 }
  func append(event: Event) {
    if events.capacity - 10 < events.count {
      reserve()
    }
    events.append(event)
  }
  func reserve() {
    print("reserving events capacity to \(events.capacity + eventsPack)")
    events.reserveCapacity(events.capacity + eventsPack)
  }
}
