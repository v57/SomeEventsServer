//
//  data-ext.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 12/3/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp
import SomeBridge

struct Location: DataRepresentable {
  var lat: Float
  var lon: Float
  init(lat: Float, lon: Float) {
    self.lat = lat
    self.lon = lon
  }
  init(data: DataReader) throws {
    lat = try data.next()
    lon = try data.next()
  }
  func save(data: DataWriter) {
    data.append(lat)
    data.append(lon)
  }
  var ilat: Int { return Int(lat) + 90 }
  var ilon: Int { return Int(lon) + 180 }
}

extension DataReader {
  func time() throws -> Time {
    return try next()
  }
  var _time: Time {
    return try! next()
  }
  func location() throws -> Location {
    return try next()
  }
  /** thread safe */
  func event() throws -> Event {
    thread.lock()
    defer { thread.unlock() }
    let id = try int()
    guard let event = events[id] else {
      throw Response.eventNotFound
    }
    return event
  }
  /** thread safe */
  func user() throws -> User {
    thread.lock()
    defer { thread.unlock() }
    let id = try int()
    guard let user = users[id] else {
      throw Response.userNotFound
    }
    return user
  }
  /** thread safe */
  func userArray() throws -> [User] {
    let ids = try intSet()
    var array = [User]()
    array.reserveCapacity(ids.count)
    thread.lock()
    defer { thread.unlock() }
    for id in ids {
      guard let user = users[id] else {
        throw Response.userNotFound
      }
      array.append(user)
    }
    return array
  }
  /** NOT thread safe */
  func chat() throws -> Chat {
    do {
      let link: ChatLink = try next()
      return link.chat
    } catch MainError.notFound {
      throw Response.chatNotFound
    } catch {
      throw error
    }
  }
  
  
//  func contents() throws -> [Content] {
//    let count = try int()
//    var contents = [Content]()
//    contents.reserveCapacity(count)
//    for _ in 0..<count {
//      let type = try uint8()
//      let id = try int()
//      let size = try uint64()
//      let author = try int()
//      let previewLoaded = try bool()
//      let loaded = try bool()
//      let content = Content(type: type, id: id, author: author, size: size)
//      content.previewLoaded = previewLoaded
//      content.loaded = loaded
//      contents.append(content)
//    }
//    return contents
//  }
}

extension DataWriter {
  func append<T>(contents value: T) where T: Sequence, T.Element == Content {
    append(value.underestimatedCount)
    for content in value {
      append(content.type)
      append(content)
    }
  }
}
