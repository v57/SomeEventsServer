//
//  message-body.swift
//  Server
//
//  Created by Admin on 10/04/2018.
//

import SomeBridge
import SomeData

enum MessageUploadStatus: UInt8 {
  case uploaded, downloaded
  static let `default` = MessageUploadStatus.Set([.downloaded])
}

protocol MessageBodyType: class, DataRepresentable {
  var type: MessageType { get }
  var string: String { get }
}

struct StorableMessageLink {
  let chat: Chat
  let message: Message
  let bodyIndex: Int
  let body: StorableMessage
  var url: FileURL {
    return body.url(message: message)
  }
  var tempURL: FileURL {
    return body.tempURL(message: message)
  }
  init(chat: Chat, message: Message, bodyIndex: Int) {
    self.chat = chat
    self.message = message
    self.bodyIndex = bodyIndex
    self.body = message.body.messages[bodyIndex] as! StorableMessage
  }
}

extension StorableMessageLink: DataRepresentable {
  init(data: DataReader) throws {
    let link: ChatLink = try data.next()
    chat = link.chat
    let index = try data.int()
    guard let message = chat[index] else { throw notFound }
    self.message = message
    bodyIndex = try data.next()
    guard let body = message.body.messages.safe(bodyIndex) as? StorableMessage else { throw notFound }
    self.body = body
  }
  
  func save(data: DataWriter) {
    chat.write(link: data)
    data.append(message.index)
    data.append(bodyIndex)
  }
}

protocol StorableMessage: class {
  var password: UInt64 { get set }
  var fileFormat: String { get }
  var isUploaded: Bool { get set }
  var fileSize: Int64 { get }
  func delete(chat: Chat, message: Message)
  func uploadBody(data: DataReader) throws
}

extension StorableMessage {
  func url(from url: FileURL, customIndex: Int) -> FileURL {
    return url + "\(customIndex)x\(password.hex).\(fileFormat)"
  }
  func url(message: Message) -> FileURL {
    return url(from: message.chat.url, customIndex: message.index)
  }
  func tempURL(message: Message) -> FileURL {
    return url(from: message.chat.tempURL, customIndex: message.index)
  }
  func delete(chat: Chat, message: Message) {
    
  }
  func link(for message: Message) -> StorableMessageLink {
    let chat = message.chat
    let index = self.index(for: message)
    return StorableMessageLink(chat: chat, message: message, bodyIndex: index)
  }
  func index(for message: Message) -> Int {
    return message.body.messages.index(where: { $0 === self })!
  }
}

extension Message {
  func storableMessage(at index: Int) -> StorableMessage? {
    return body.messages.safe(index) as? StorableMessage
  }
}

struct MessageBody {
  var messages = [MessageBodyType]()
  var isDeleted: Bool {
    return messages.isEmpty
  }
  var string: String {
    if isDeleted {
      return "(deleted)"
    } else {
      return messages.map { $0.string }.joined(separator: " ")
    }
  }
  mutating func delete(message: Message) {
    messages.forEach {
      ($0 as? StorableMessage)?.delete(chat: message.chat, message: message)
    }
    messages.removeAll()
  }
  init() {
    
  }
  init(text: String) {
    guard !text.isEmpty else { return }
    messages.append(TextMessage(text: text))
  }
}

extension MessageBody: CustomStringConvertible {
  var description: String { return string }
}

extension MessageBody: DataRepresentable {
  init(data: DataReader) throws {
    messages = try data.array {
      let type: MessageType = try data.next()
      switch type {
      case .text:
        return try TextMessage(data: data)
      case .richText:
        return try RichTextMessage(data: data)
      case .photo:
        return try PhotoMessage(data: data)
      case .video:
        return try VideoMessage(data: data)
      case .coordinate:
        return try CoordinateMessage(data: data)
      }
    }
  }
  func save(data: DataWriter) {
    data.append(messages.count)
    messages.forEach {
      data.append($0)
    }
  }
}

class TextMessage: MessageBodyType {
  var type: MessageType { return .text }
  var string: String { return text }
  var text: String
  init(text: String) {
    self.text = text
  }
  required init(data: DataReader) throws {
    text = try data.next()
  }
  func save(data: DataWriter) {
    data.append(type)
    data.append(text)
  }
}

class RichTextMessage: MessageBodyType {
  var type: MessageType { return .richText }
  var string: String { return text }
  var text: String
  var options: RichTextOption.Set
  var font: RichTextFont
  required init(data: DataReader) throws {
    text = try data.next()
    options = try data.next()
    font = try data.next()
  }
  func save(data: DataWriter) {
    data.append(type)
    data.append(text)
    data.append(options)
    data.append(font)
  }
}


class PhotoMessage: MessageBodyType, StorableMessage {
  var fileSize: Int64 { return Int64(photoData.size) }
  var type: MessageType { return .photo }
  var string: String { return .imageEmoji }
  var fileFormat: String { return "jpg" }
  var isUploaded: Bool {
    get { return status[.uploaded] }
    set { status[.uploaded] = newValue }
  }
  var photoData: PhotoData
  var password: UInt64
  var status: MessageUploadStatus.Set
  
  required init(data: DataReader) throws {
    photoData = try data.next()
    password = try data.next()
    status = try data.next()
  }
  func save(data: DataWriter) {
    data.append(type)
    data.append(photoData)
    data.append(password)
    data.append(status)
  }
  func uploadBody(data: DataReader) throws {
    photoData = try data.next()
    try fileSize.checkSize(max: .photo)
  }
}

class VideoMessage: MessageBodyType, StorableMessage {
  var fileSize: Int64 { return Int64(videoData.size) }
  var type: MessageType { return .video }
  var string: String { return .videoEmoji }
  var fileFormat: String { return "mp4" }
  var isUploaded: Bool {
    get { return status[.uploaded] }
    set { status[.uploaded] = newValue }
  }
  var videoData: VideoData
  var password: UInt64
  var status: MessageUploadStatus.Set
  
  required init(data: DataReader) throws {
    videoData = try data.next()
    password = try data.next()
    status = try data.next()
  }
  func save(data: DataWriter) {
    data.append(type)
    data.append(videoData)
    data.append(password)
    data.append(status)
  }
  func uploadBody(data: DataReader) throws {
    videoData = try data.next()
    try videoData.check()
    try fileSize.checkSize(max: .miniVideo)
  }
}


class CoordinateMessage: MessageBodyType {
  var type: MessageType { return .coordinate }
  var string: String { return .mapEmoji }
  var latitude: Float
  var longitude: Float
  
  required init(data: DataReader) throws {
    latitude = try data.next()
    longitude = try data.next()
  }
  func save(data: DataWriter) {
    data.append(type)
    data.append(latitude)
    data.append(longitude)
  }
}
