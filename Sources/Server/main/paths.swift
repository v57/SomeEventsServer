//
//  paths.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 1/11/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeBridge

var dbPath: String = "~/Music/faggot/"
var contentPath: String = "~/Music/faggot/"
var backupPath: String = "~/Music/faggot/backups/"

extension String {
  public var dbURL: FileURL {
    return (dbPath + self).fileURL
  }
  public var backupURL: FileURL {
    return (dbPath + self).fileURL
  }
  public var contentURL: FileURL {
    return (contentPath + self).fileURL
  }
  public var htmlTemplates: FileURL {
    return (dbPath + "templates/" + self).fileURL
  }
}

//extension FileURL {
//  static let photos = "data/photos.db".dbURL
//  static let videos = "data/videos.db".dbURL
//  static let users = "data/users.db".dbURL
//  static let events = "data/events.db".dbURL
//  static let chats = "data/chats.db".dbURL
//  static let tasks = "data/tasks.db".dbURL
//  static let lists = "data/lists.db".dbURL
//  static let push = "data/push.db".dbURL
//  static let ids = "data/ids.db".dbURL
//  static let versions = "data/versions.db".dbURL
//  static let moderators = "data/moderators.db".dbURL
//}

func createDirectories() {
  
  dbPath.fileURL.create()
  contentPath.fileURL.create()
  
  "templates".dbURL.create()
  
  "content/previews/photos".contentURL.create()
  "content/previews/videos".contentURL.create()
  "content/photos".contentURL.create()
  "content/videos".contentURL.create()
  "content/avatars".contentURL.create()
  "content/events".contentURL.create()
  
  "temp/previews/photos".contentURL.create()
  "temp/previews/videos".contentURL.create()
  "temp/photos".contentURL.create()
  "temp/videos".contentURL.create()
  "temp/avatars".contentURL.create()
  "temp/events".contentURL.create()
  
  "backups".dbURL.create()
  "data".dbURL.create()
  
  "bots".contentURL.create()
  "bots/names.txt".contentURL.create()
  "bots/events.txt".contentURL.create()
}

extension Event {
  func createDirectories() {
    "content/events/\(id)".contentURL.create()
    "content/events/\(id)/previews".contentURL.create()
    "temp/events/\(id)".contentURL.create()
    "temp/events/\(id)/previews".contentURL.create()
  }
}

protocol PhysicalContent {
  var id: Int { get }
  var password: UInt64 { get }
  var fileFormat: String { get }
  func url(event: Event) -> FileURL
  func tempURL(event: Event) -> FileURL
  func previewURL(event: Event) -> FileURL
  func previewTempURL(event: Event) -> FileURL
}

extension PhysicalContent {
  func link(event: Event) -> String {
    return "\(address.ip):\(httpPort)/events/\(event.id)/\(id)-\(password.hex).\(fileFormat)"
  }
  func previewLink(event: Event) -> String {
    return "\(address.ip):\(httpPort)/events/\(event.id)/previews/\(id)-\(password.hex).jpg"
  }
  func url(event: Event) -> FileURL {
    return "content/events/\(event.id)/\(id)-\(password.hex).\(fileFormat)".contentURL
  }
  func previewURL(event: Event) -> FileURL {
    return "content/events/\(event.id)/previews/\(id)-\(password.hex).jpg".contentURL
  }
  func tempURL(event: Event) -> FileURL {
    return "temp/events/\(event.id)/\(id)-\(password.hex).\(fileFormat)".contentURL
  }
  func previewTempURL(event: Event) -> FileURL {
    return "temp/events/\(event.id)/previews/\(id)-\(password.hex).jpg".contentURL
  }
}

extension PhotoContent: PhysicalContent {
  var fileFormat: String { return "jpg" }
  
  var oldURL: FileURL {
    return "content/photos/\(id).jpg".contentURL
  }
  var oldPreviews: FileURL {
    return "content/previews/photos/\(id).jpg".contentURL
  }
}

extension VideoContent: PhysicalContent {
  var fileFormat: String { return "m4v" }
  
  var oldURL: FileURL {
    return "content/videos/\(id).m4v".contentURL
  }
  var oldPreviews: FileURL {
    return "content/previews/videos/\(id).jpg".contentURL
  }
  
//  var video: FileURL { return "content/videos/\(self).m4v".contentURL }
//  var videoTemp: FileURL { return "temp/videos/\(self).m4v".contentURL }
//  var videoPreview: FileURL { return "content/previews/videos/\(self).jpg".contentURL }
//  var videoPreviewTemp: FileURL { return "temp/previews/videos/\(self).jpg".contentURL }
//  
//  var photo: FileURL { return "content/photos/\(self).jpg".contentURL }
//  var photoTemp: FileURL { return "temp/photos/\(self).jpg".contentURL }
//  var photoPreview: FileURL { return "content/previews/photos/\(self).jpg".contentURL }
//  var photoPreviewTemp: FileURL { return "temp/previews/photos/\(self).jpg".contentURL }
}

extension User {
  var avatarURL: FileURL { return "content/avatars/\(id).jpg".contentURL }
  var avatarTemp: FileURL { return "temp/avatars/\(id).jpg".contentURL }
}

