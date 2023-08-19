//
//  db.swift
//  faggot server
//
//  Created by Дмитрий Козлов on 26/01/16.
//  Copyright © 2016 anus. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class DB {
  var willSave = true
  /*
  fileprivate var photos = [PhotoContent?](repeating: nil, count: maxPhotos)
  fileprivate var videos = [VideoContent?](repeating: nil, count: maxVideos)
  
  fileprivate var photosCount = 0
  fileprivate var videosCount = 0
  
  
  var stats = DebugConnection.Stats()
  
  var mapSubs = [Connection]()
 */
  
  func printAll() {
    printStats()
    users.printAll()
    events.printAll()
//    stats.printNetwork()
    print("-------------")
    for user in users.array {
      for connection in user.currentConnections {
        for sub in connection.subscriptions {
          print("\(user.name) - \(sub)")
        }
      }
    }
  }
  func printStats() {
//    print("-------------")
//    print("Statistics")
//    var dbSize: UInt64 = 0
//    dbSize += du("events")
//    dbSize += du("info")
//    dbSize += du("users")
//    dbSize += du("photos data")
//    dbSize += du("videos data")
//    print("db size: \(dbSize.bytesString)")
//    print("user photos size: \(du_s("userpics").bytesString)")
//    print("photos size: \(du_s("photos").bytesString)")
//    print("videos size: \(du_s("videos").bytesString)")
  }
  
  func printCMD() {
    var a: UInt8 = 0
    while let c = cmd(rawValue: a) {
      var string = " \(a): \(c)"
      var uses = 0
      if api.unauthFunctions[c] != nil {
        uses += 1
        string += " unauth"
      }
      if api.authFunctions[c] != nil {
        uses += 1
        string += " auth"
      }
      if api.fileFunctions[c] != nil {
        uses += 1
        string += " files"
      }
      if uses == 0 {
        string = ">unused:" + string
      }
      print(string)
      a += 1
    }
  }
  
  func printSUBCMD() {
    var a: UInt8 = 0
    while let c = cmd(rawValue: a) {
      print("\(a): \(c)")
      a += 1
    }
  }
  
  func systemMessage(_ text: String) {
    var connections = Set<Connection>()
    users.array.forEach { connections += $0.currentConnections }
    guard connections.count > 0 else {
      print("no users online")
      return
    }
    serverEvents.systemMessage(text: text, to: connections)
  }
  
  func start() {
    let timer = CPUTimer(name: "db loading")
    timer.resume()
    print("loading db")
    ceo.start()
    try! load()
  }
  func stop() {
    guard willSave else { return }
    let a = Time.abs
    save()
    let b = Time.abs
    print("stop time: \(b-a) sec")
  }
  func backup() {
    let a = Time.abs
    var i = 0
    while true {
      i += 1
      if !"\(i)".backupURL.exists {
        save()
        "data".dbURL.copy(to: "\(i)/data".backupURL)
        print("created backup \(i)")
        break
      }
    }
    let b = Time.abs
    print("backup time: \(b-a) sec")
  }
  
  func restore(_ i: Int) {
    let a = Time.abs
    if !"\(i)".backupURL.exists {
      print("no data")
    } else {
      backup()
      "\(i)/data".backupURL.copy(to: "data".dbURL)
    }
    let b = Time.abs
    print("restore time: \(b-a) sec")
  }
  
  func save() {
    
    thread.lock()
    ceo.save()
    thread.unlock()
    print("saved")
    /*
    // other
    print("saving some shet")
    let info = DataWriter()
    info.append(users.count)
    info.append(events.count)
    info.append(photosCount)
    info.append(videosCount)
    
    // photos
    print("saving photos")
    let photos  = DataWriter()
    var count = 0
    for photo in self.photos where photo != nil {
      count += 1
    }
    photos.append(count)
    for photo in self.photos {
      photo?.save(to: photos)
    }
    
    // videos
    print("saving videos")
    let videos  = DataWriter()
    count = 0
    for video in self.videos where video != nil {
      count += 1
    }
    videos.append(count)
    for video in self.videos {
      video?.save(to: videos)
    }
    
    try? info.write(to: .info)
    try? photos.write(to: .photos)
    try? videos.write(to: .videos)
    */
  }
  
  func load() throws {
    createDirectories()
    ceo.load()
//    for manager in ceo.managers {
//      guard let manager = manager as? CustomSaveable else { continue }
//      do {
//        try manager.load()
//      } catch {
//        fatalError("manager \(className(manager)) is fucked up")
//      }
//    }
    /*
    // info
    if let info = DataReader(url: .info) {
      users.count = try info.int()
      events.count = try info.int()
      photosCount = try info.int()
      videosCount = try info.int()
    } else {
      print("no info")
    }
    
    // photos
    if let data = DataReader(url: .photos) {
      let count = try data.int()
      for _ in 0..<count {
        let photo = try PhotoContent(data: data)
        setPhoto(photo)
      }
      print("loaded \(count) photos")
    } else {
      print("no photos data")
    }
    // videos
    if let data = DataReader(url: .videos) {
      let count = try data.int()
      for _ in 0..<count {
        let video = try VideoContent(data: data)
        setVideo(video)
      }
      print("loaded \(count) videos")
    } else {
      print("no videos data")
    }
    
    // managers
    for manager in managers {
      guard let manager = manager as? CustomSaveable else { continue }
      do {
        try manager.load()
      } catch {
        fatalError("manager \(className(manager)) is fucked up")
      }
    }
 */
  }
}
  /*
  
  
  ///////////////////////
  // MARK:- Set
  ///////////////////////
  
  
  func setPhoto(_ photo: PhotoContent) {
    photos[photo.id] = photo
  }
  func setVideo(_ video: VideoContent) {
    videos[video.id] = video
  }
  
  
  ///////////////////////
  // MARK:- Event
  ///////////////////////
  
  
  func addPhoto(event: Event, author: Int, notify: Bool, ignore: Connection?) -> Content {
    let id = photosCount
    photosCount += 1
    let content = PhotoContent(id: id, author: author)
    photos[id] = content
    event.add(content: content)
    if notify {
      serverEvents.newContent(event: event, content: content, ignore: ignore)
    }
    return content
  }
  func photo(_ id: Int) -> PhotoContent! {
    guard id >= 0 && id < photos.count else { return nil }
    return photos[id]
  }
  func addVideo(event: Event, author: Int, notify: Bool, ignore: Connection?) -> Content {
    let id = videosCount
    videosCount += 1
    let content = VideoContent(id: id, author: author)
    videos[id] = content
    event.add(content: content)
    if notify {
      serverEvents.newContent(event: event, content: content, ignore: ignore)
    }
    return content
  }
  func video(_ id: Int) -> VideoContent! {
    guard id >= 0 && id < videos.count else { return nil }
    return videos[id]
  }
  func content(_ id: Int, type: UInt8) -> Content! {
    if type == 0 {
      return photo(id)
    } else if type == 1 {
      return video(id)
    } else {
      return nil
    }
  }
}

extension Bots {
  func addPhotos() -> [PhotoContent] {
    var array = [PhotoContent]()
    let photos = "content/photos".contentURL.content.images.count
    for i in 0..<photos {
      let author = 0
      
      let id = i
      db.photosCount += 1
      let content = PhotoContent(id: id, author: author)
      
      let url = content.oldURL
      let size = url.fileSize
      
      
      content.size = UInt64(size)
      db.photos[id] = content
      array.append(content)
    }
    print("added \(photos) photos")
    return array
  }
  func addVideos() -> [VideoContent] {
    var array = [VideoContent]()
    let videos = "content/videos".contentURL.content.videos.count
    for i in 0..<videos {
      let author = 0
      
      let id = i
      db.videosCount += 1
      let content = VideoContent(id: id, author: author)
      
      let url = content.oldURL
      let size = url.fileSize
      
      content.size = UInt64(size)
      db.videos[id] = content
      array.append(content)
    }
    print("added \(videos) videos")
    return array
  }
}

*/
