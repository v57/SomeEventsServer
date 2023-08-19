//
//  admin.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 1/9/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
#if os(macOS)
  import Cocoa
#endif

var videoChance: Float = 0.1

class Bots: ServerManager {
  
  var avatars = [FileURL]()
  var photos = [FileURL]()
  var videos = [FileURL]()
  var photoContent = [PhotoContent]()
  var videoContent = [VideoContent]()
  
  var randomPhoto: PhotoContent { return names.photo }
  var randomVideo: VideoContent { return names.video }
  
  
  func addPhotos() {
    let photos = "content/photos".contentURL.content.images.count
    for _ in 0..<photos {
      let author = 0
      
      let content = PhotoContent(id: photoContent.count, author: author)
      
      let url = content.oldURL
      let size = url.fileSize
      
      #if os(macOS)
        if let image = NSImage(contentsOf: url.url) {
          content.photoData.width = Int16(image.size.width)
          content.photoData.height = Int16(image.size.height)
        }
      #endif
      content.photoData.size = Int32(size)
        
      photoContent.append(content)
    }
    print("added \(photos) photos")
  }
  func addVideos() {
    let videos = "content/videos".contentURL.content.videos.count
    for _ in 0..<videos {
      let author = 0
      let content = VideoContent(id: videoContent.count, author: author)
      
      let url = content.oldURL
      let size = url.fileSize
      content.videoData.size = UInt64(size)
      videoContent.append(content)
    }
    print("added \(videos) videos")
  }
  
  @discardableResult
  func spawn() -> User {
//    let id = users.count
    let name = names.user
    let user = User(name: name)
    user.password = 1488
    user.avatarVersion = user.avatarURL.exists ? 1 : 0
    users.add(user: user)
    add(events: user.events.count, user: user)
    return user
  }
  func add(events count: Int, user: User) {
    guard count > 0 else { return }
    let now: Time = .now
    var start: Time = .now - 5 * .year // .random(min: .now - 5 * .year, max: .now)
    for _ in 0..<count {
      if start != now {
        start += .random(min: .day * 10, max: .month * 2)
      }
      start = min(start,now)
      
      let name = names.event
      let event = Event(id: events.count, name: name, owner: user.id)
      event.createdTime = start
      event.startTime = start
      event.endTime = event.startTime + .day
      event.lat = -180.0--180.0
      event.lon = -90.0--90.0
      
      events.create(event: event, user: user, notify: false)
      add(content: event.contentCount, event: event)
    }
  }
  func add(content count: Int, event: Event) {
    for _ in 0..<count {
      let content = Float.seed() < videoChance ? names.video : names.photo
      
      event.add(content: content, notify: false, from: nil)
    }
  }
  
  func comment(event: Event, by user: User) {
    let text = names.comment
    let comments = event.comments
    var time: Time
    if let message = comments.messages.last {
      time = message.time + Time(0 -- 2)
    } else {
      time = event.createdTime + Time(0 -- 2)
    }
    
    let message = Message(from: user.id, time: time, body: text, chat: comments)
    comments.messages.append(message)
  }
  
  func add(friends count: Int, user: User) {
    let count = count - user.friends.count
    guard count > 0 else { return }
    for _ in 0..<count {
      let id = randomUser { !user.friends.contains($0) }
      let u = users[id]!
      
      user.add(friend: u, notify: false)
//      u.add(friend: user, notify: false)
    }
  }
  func subscribe(user: User) {
    for u in users.array {
      if u.willSubscribe {
        user.subscribe(to: u, notify: false)
      }
    }
  }
  func randomUser(condition: (Int)->Bool) -> Int {
    while true {
      let id = users.array.any.id
      if condition(id) {
        return id
      }
    }
  }
  override func start() {
    
    
//    let currentPhotos = "\(root)/content/photos".path.content.images.count
    
    let folder = "bots/".contentURL
    avatars = (folder + "avatars").content.images
    photos = (folder + "photos").content.images
    videos = (folder + "videos").content.videos
    
    print("bot avatars: \(avatars.count)")
    print("bot photos: \(photos.count)")
    print("bot videos: \(videos.count)")
    
    let console = Console(name: "bots")
    console.add(function: "merge") {
      self.merge()
    }.description = "# move content from bots/ to content/"
    console.set(function: "bots") {
      self.generate()
    }.description = "# generate bots"
    terminal.add(command: console)
  }
  
  func merge() {
    print("merging avatars")
    "bots/avatars".contentURL.copy(to: "content/avatars".contentURL)
    print("merging photos")
    "bots/photos".contentURL.copy(to: "content/photos".contentURL)
    print("merging videos")
    "bots/videos".contentURL.copy(to: "content/videos".contentURL)
    print("merging previews")
    "bots/previews".contentURL.copy(to: "content/previews".contentURL)
    print("merged")
  }
  
  func generate() {
    
    // content
    print("adding photos")
    addPhotos()
    print("adding videos")
    addVideos()
    
    guard photoContent.count > 0 else {
      print("bots cannot be created: no photos")
      return
    }
    guard videoContent.count > 0 else {
      print("bots cannot be created: no videos")
      return
    }
    
    // users
    print("counting bots")
    let botsCount = "content/avatars".contentURL.content.images.count - 1
    print("spawning admin")
    spawnAdmin()
    print("spawning users")
    for _ in 0..<botsCount {
      spawn()
    }
    print("adding friends, subscribing, commenting")
    for user in users.array {
      add(friends: user.friends.count, user: user)
      subscribe(user: user)
      let events = user.events.events
      for event in events {
        if event.popularity%% {
          _ = event.view(by: user)
          if user.willComment {
            comment(event: event, by: user)
          }
        }
      }
      
    }
    let admin = users[0]!
    for i in 1..<50 {
      let user = users[i]!
      admin.add(friend: user, notify: false)
      user.add(friend: admin, notify: false)
    }
    print("inviting to events")
    for user in users.array {
      guard !user.events.isEmpty else { continue }
      guard user.friends.count > 1 else { continue }
      for event in user.events.events {
        guard event.owner == user.id else { continue }
        guard 10%% else { continue }
        var ids = Set<Int>()
        let count = 1--10
        for _ in 0..<count {
          ids.insert(user.friends.any)
        }
        for id in ids {
          try? event.invite(by: user, user: users[id]!, notify: false)
        }
      }
    }
    print("generated \(botsCount) bots")
  }
  
  func spawnAdmin() {
    let admin = User(name: "admin")
    admin.avatarVersion = admin.avatarURL.exists ? 1 : 0
    admin.password = 1488
    users.add(user: admin)
    add(events: 50, user: admin)
  }
}

// name generators
private let names = Names()
private class Names {
  var event: String {
    if events.count == 0 {
      updateEvents()
    }
    return self.events.popLast()!
  }
  var user: String {
    if users.count == 0 {
      updateUsers()
    }
    return self.users.popLast()!
  }
  
  var photo: PhotoContent {
    if photos.count == 0 {
      updatePhotos()
    }
    return self.photos.popLast()!
  }
  
  var video: VideoContent {
    if videos.count == 0 {
      updateVideos()
    }
    return self.videos.popLast()!
  }
  
  var comment: String {
    return comments.any
  }
  
  private var eventsRound = 1
  private var allEvents: [String]
  private var events: [String]
  
  private var usersRound = 1
  private var allUsers: [String]
  private var users: [String]
  
  private var photos: [PhotoContent]
  private var videos: [VideoContent]
  private var comments: [String]
  
  init() {
    let defaultUsers = ["dimas", "artem", "vanya", "stas", "slava", "asian", "hach", "pink guy", "mamka admina"]
    let defaultEvents = ["E3", "Вписка", "New year", "Comicon", "Свадьба геев", "Украина 2", "Hair cake"]
    
    do {
      let events = try "bots/events.txt".contentURL.open().string.lines
      guard events.count > 0 else { throw NamesError.empty }
      allEvents = events
    } catch {
      allEvents = defaultEvents
    }
    
    do {
      let users = try "bots/names.txt".contentURL.open().string.lines
      guard users.count > 0 else { throw NamesError.empty }
      allUsers = users
    } catch {
      allUsers = defaultUsers
    }
    
    do {
      comments = try "bots/comments.txt".contentURL.open().string.lines
    } catch {
      comments = ["hi"]
    }
    
    events = allEvents.shuffle(password: randomCount)
    users = allUsers.shuffle(password: randomCount)
    photos = bots.photoContent.shuffle(password: randomCount)
    videos = bots.videoContent.shuffle(password: randomCount)
    
  }
  
  private func updateEvents() {
    eventsRound += 1
    events = allEvents.shuffle(password: randomCount).map { "\($0) \(eventsRound)" }
  }
  
  private func updateUsers() {
    usersRound += 1
    users = allUsers.shuffle(password: randomCount).map { "\($0) \(usersRound)" }
  }
  
  private func updatePhotos() {
    photos = bots.photoContent.shuffle(password: randomCount)
  }
  
  private func updateVideos() {
    videos = bots.videoContent.shuffle(password: randomCount)
  }
  
  private enum NamesError: Error {
    case empty
  }
}

// params

private extension User {
  // generation
  var hasEvents: Bool {
    guard !isAdmin else { return true }
    return id < 10 || id.chance(40) }
  var muchEvents: Bool {
    guard !isAdmin else { return true }
    return id < 10 || (hasEvents && id.chance(10)) }
  var eventsCount: Int {
    guard hasEvents else { return 0 }
    let count = Float.seed()
    if muchEvents {
      return 10 + Int(count * 50.0)
    } else {
      return 1 + Int(count * 5.0)
    }
  }
  
  // interaction
  var isPitard: Bool {
    guard !isAdmin else { return false }
    return id > 10 && 20%% } // никто его не смотрит
  var isPopular: Bool {
    guard !isAdmin else { return true }
    return id < 10 || (hasEvents && !isPitard && 1%%) }
  var willComment: Bool {
    if isPitard {
      return 10%%
    } else {
      return 40%%
    }
  }
  var friendsCount: Int {
    if isPitard {
      return 0
    } else if isPopular {
      return 10 + Int(Float.seed() * 10)
    } else {
      return 3 + Int(Float.seed() * 7)
    }
  }
  var willSubscribe: Bool {
    if isPitard {
      return false
    } else if isPopular {
      return 70%%
    } else {
      return 10%%
    }
  }
}

private extension Event {
  var contentCount: Int { return Int(5.0 + Float.seed() * 50.0) }
  var popularity: Float {
    guard !owner.isAdmin else { return 1.0 }
    var popularity: Float = 0.0
    
    let content = self.content.count
    
    if content > 50 {
      popularity += 0.4
    } else if content > 25 {
      popularity += 0.2
    } else if content > 10 {
      popularity += 0.1
    }
    
    popularity += Float.seed()
    
    popularity = max(0,popularity)
    popularity = min(1,popularity)
    
    return popularity
  }
}

private extension Int {
  var isAdmin: Bool { return self == 0 }
}

// random functions
private extension Array {
  var random: Element {
    let index = Int(Float.seed() * Float(self.count))
    return self[index]
  }
  mutating func pickRandom() -> Element {
    let index = Int(Float.seed() * Float(self.count))
    let result = self[index]
    remove(at: index)
    return result
  }
}

private extension Int {
  func chance(_ value: Float) -> Bool {
    return Float.seed() < value
  }
}

private var randomCount = 0

public func randomSeed() -> Int {
  randomCount += 1
  return randomCount
}

extension Set {
  var any: Element {
    let n = Int.random(in: 0..<count)
    let index = self.index(startIndex, offsetBy: n)
    return self[index]
  }
}

