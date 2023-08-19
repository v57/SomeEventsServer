//
//  content.swift
//  PerfectThread
//
//  Created by Дмитрий Козлов on 7/18/17.
//

import SomeFunctions
import SomeData
import SomeBridge

extension ContentType {
  var `class`: Content.Type {
    switch self {
    case .photo:
      return PhotoContent.self
    case .video:
      return VideoContent.self
//    case .stream:
//      return StreamContent.self
//    case .audioStream:
//      return AudioContent.self
//    case .link:
//      return LinkContent.self
//    case .youtube:
//      return YouTubeContent.self
    }
  }
}

extension Event: Hashable {
  var hashValue: Int { return id.hashValue }
  static func == (l: Event, r: Event) -> Bool {
    return l.id == r.id
  }
}

class Content: DataRepresentable, Versionable {
  static var version = 0
  
  var type: ContentType { overrideRequired() }
  let id: ID
  let author: ID
  var time: Time
  
  var isProtected: Bool {
    get { overrideRequired() }
    set { overrideRequired() }
  }
  
  init(id: Int, author: Int) {
    self.id = id
    self.author = author
    self.time = .now
  }
  required init(data: DataReader) throws {
    id = try data.int()
    author = try data.int()
    time = try data.time()
  }
  func save(data: DataWriter) {
    data.append(id)
    data.append(author)
    data.append(time)
  }
  
  static func == (l: Content, r: Content) -> Bool {
    return l.id == r.id
  }
}

class PhotoContent: Content {
  override var type: ContentType { return .photo }
  var size: UInt64 {
    return UInt64(photoData.size)
  }
  var options = PhotoOptions.Set()
  var photoData = PhotoData()
  var password: UInt64
  override init(id: Int, author: Int) {
    password = .random()
    super.init(id: id, author: author)
  }
  required init(data: DataReader) throws {
    options = try data.next()
    password = try data.next()
    photoData = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(options)
    data.append(password)
    data.append(photoData)
    super.save(data: data)
  }
  override var isProtected: Bool {
    get { return options.contains(.protected) }
    set { options.set(.protected,newValue) }
  }
  var isUploaded: Bool {
    get { return options.contains(.uploaded) }
    set { options.set(.uploaded,newValue) }
  }
  var isPreviewUploaded: Bool {
    get { return options.contains(.previewUploaded) }
    set { options.set(.previewUploaded,newValue) }
  }
}
class VideoContent: Content {
  override var type: ContentType { return .video }
  var size: UInt64 {
    return videoData.size
  }
  var options = VideoOptions.Set()
  var videoData = VideoData()
  var password: UInt64
  override init(id: Int, author: Int) {
    password = .random()
    super.init(id: id, author: author)
  }
  required init(data: DataReader) throws {
    options = try data.next()
    password = try data.next()
    videoData = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(options)
    data.append(password)
    data.append(videoData)
    super.save(data: data)
  }
  override var isProtected: Bool {
    get { return options.contains(.protected) }
    set { options.set(.protected,newValue) }
  }
  var isUploaded: Bool {
    get { return options.contains(.uploaded) }
    set { options.set(.uploaded,newValue) }
  }
  var isPreviewUploaded: Bool {
    get { return options.contains(.previewUploaded) }
    set { options.set(.previewUploaded,newValue) }
  }
}

/*
class AudioContent: Content {
  override var type: ContentType { return .audio }
  var size = UInt64()
  var options = AudioOptions.Set()
  var password: UInt64
  override init(id: Int, author: Int) {
    password = .random()
    super.init(id: id, author: author)
  }
  required init(data: DataReader) throws {
    options = try data.next()
    size = try data.next()
    password = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(options)
    data.append(size)
    data.append(password)
    super.save(data: data)
  }
  override var isProtected: Bool {
    get { return options.contains(.protected) }
    set { options.insert(.protected) }
  }
  var isUploaded: Bool {
    get { return options.contains(.uploaded) }
    set { options.set(.uploaded,newValue) }
  }
}
class YouTubeContent: Content {
  override var type: ContentType { return .youtube }
  var link = String()
  var options = YoutubeOptions.Set()
  // check video "http://gdata.youtube.com/feeds/api/videos/\(link)"
  init(id: Int, author: Int, link: String) {
    self.link = link
    super.init(id: id, author: author)
  }
  required init(data: DataReader) throws {
    options = try data.next()
    link = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(options)
    data.append(link)
    super.save(data: data)
  }
  override var isProtected: Bool {
    get { return options.contains(.protected) }
    set { options.set(.protected,newValue) }
  }
}
class LinkContent: Content {
  override var type: ContentType { return .link }
  var link: String
  var options = LinkOptions.Set()
  init(id: Int, author: Int, link: String) {
    self.link = link
    super.init(id: id, author: author)
  }
  required init(data: DataReader) throws {
    options = try data.next()
    link = try data.string()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(options)
    data.append(link)
    super.save(data: data)
  }
  override var isProtected: Bool {
    get { return options.contains(.protected) }
    set { options.set(.protected,newValue) }
  }
}
class StreamContent: Content {
  override var type: ContentType { return .stream }
  var options = StreamOptions.Set()
  var quality = VideoQuality.q720
  var password: UInt64
  override init(id: Int, author: Int) {
    password = .random()
    super.init(id: id, author: author)
  }
  required init(data: DataReader) throws {
    options = try data.next()
    quality = try data.next()
    password = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(options)
    data.append(quality)
    data.append(password)
    super.save(data: data)
  }
  override var isProtected: Bool {
    get { return false }
    set {  }
  }
  var isStreaming: Bool {
    get { return options.contains(.streaming) }
    set { options.set(.streaming,newValue) }
  }
}

class AudioStreamContent: Content {
  override var type: ContentType { return .audioStream }
  var options = AudioStreamOptions.Set()
  var password: UInt64
  override init(id: Int, author: Int) {
    password = .random()
    super.init(id: id, author: author)
  }
  required init(data: DataReader) throws {
    options = try data.next()
    password = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(options)
    data.append(password)
    super.save(data: data)
  }
  override var isProtected: Bool {
    get { return false }
    set {  }
  }
  var isStreaming: Bool {
    get { return options.contains(.streaming) }
    set { options.set(.streaming,newValue) }
  }
}
*/

extension DataWriter {
  func append(_ value: ContentType) {
    self.append(value.rawValue)
  }
}
extension DataReader {
  func content() throws -> Content {
    return try contentType().class.init(data: self)
  }
  func contentType() throws -> ContentType {
    return try next()
  }
}

extension vec2 where T == ID {
  @discardableResult
  func content() throws -> Content {
    guard let event = events[x] else { throw Response.eventNotFound }
    guard let content = event.content[y] else { throw Response.contentNotFound }
    return content
  }
  @discardableResult
  func comment() throws -> Message {
    guard let event = events[x] else { throw Response.eventNotFound }
    guard let comment = event.comments[y] else { throw Response.messageNotFound }
    return comment
  }
}
