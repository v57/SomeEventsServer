//
//  server-files.swift
//  Server
//
//  Created by Дмитрий Козлов on 2/27/17.
//
//

import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp
import SomeBridge

extension Int64 {
  static var avatar = Int64(1.mb)
  static var photo = Int64(10.mb)
  static var miniVideo = Int64(1.gb)
  static var video = Int64(50.gb)
  static var preview = Int64(200.kb)
  func checkSize(max: Int64) throws {
    guard self > 0 else { throw Response.wrongFileSize }
    guard self < max else { throw Response.fileIsTooBig }
  }
}

extension API {
  func files(commands: inout [cmd: ServerFunction]) {
    commands[.download] = download
    commands[.upload] = upload
  }
}

private func download(connection: Connection, data: DataReader) throws {
  connection.user = try users.login(id: data.next(), password: data.next())
  let type: FileType = try data.next()
  switch type {
  case .avatar:
    try getAvatar(connection: connection, data: data)
  case .photo:
    try getPhoto(connection: connection, data: data)
  case .photoPreview:
    try getPhotoPreview(connection: connection, data: data)
  case .video:
    try getVideo(connection: connection, data: data)
  case .videoPreview:
    try getVideoPreview(connection: connection, data: data)
//  case .audio:
//    try getAudio(connection: connection, data: data)
  case .chatFile:
    try getChatFile(connection: connection, data: data)
  }
}

private func upload(connection: Connection, data: DataReader) throws {
  let id: ID = try data.next()
  let password: UInt64 = try data.next()
  connection.user = try users.login(id: id, password: password)
  let type: FileType = try data.next()
  switch type {
  case .avatar:
    try addAvatar(connection: connection, data: data)
  case .photo:
    try addPhoto(connection: connection, data: data)
  case .photoPreview:
    try addPhotoPreview(connection: connection, data: data)
  case .video:
    try addVideo(connection: connection, data: data)
  case .videoPreview:
    try addVideoPreview(connection: connection, data: data)
//  case .audio:
//    try addAudio(connection: connection, data: data)
  case .chatFile:
    try addChatFile(connection: connection, data: data)
  }
}

private func getAudio(connection: Connection, data: DataReader) throws {
}

private func addAudio(connection: Connection, data: DataReader) throws {
}

private func addAvatar(connection: Connection, data: DataReader) throws {
  print(" adding avatar")
  let total = try data.int64()
  try total.checkSize(max: .avatar)
  try connection.read(connection.user.avatarURL, total: total) {
    thread.lock()
    connection.user.updateAvatar(notify: true)
    thread.unlock()
  }
}

private func getAvatar(connection: Connection, data: DataReader) throws {
  let user = try data.user()
  try connection.send(user.avatarURL, data: data)
}

private func addPhoto(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let photoid = try data.int()
  let photoData: PhotoData = try data.next()
  let total = Int64(photoData.size)
  print("photo \(photoid) uploading")
  
  try total.checkSize(max: .photo)
  let content = try event.photo(id: photoid, by: connection.user)
  try content.check(author: connection)
  
  try connection.read(content.url(event: event), total: total) {
    thread.lock()
    content.photoData = photoData
    content.isUploaded = true
    print("photo \(photoid) uploaded")
    serverEvents.contentUploaded(event: event, content: content)
    thread.unlock()
  }
}

private func addPhotoPreview(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let photoid = try data.int()
  let total = try data.int64()
  print("photo preview \(photoid) uploading")
  
  try total.checkSize(max: .preview)
  let content = try event.photo(id: photoid, by: connection.user)
  try content.check(author: connection)
  
  try connection.read(content.previewURL(event: event), total: total) {
    thread.lock()
    content.isPreviewUploaded = true
    print("photo preview \(photoid) uploaded")
    serverEvents.contentPreviewUploaded(event: event, content: content)
    thread.unlock()
  }
}

private func addVideo(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let photoid = try data.int()
  let videoData: VideoData = try data.next()
  try videoData.check()
  let total = Int64(bitPattern: videoData.size)
  
  try total.checkSize(max: .video)
  let content = try event.video(id: photoid, by: connection.user)
  try content.check(author: connection)
  
  try connection.read(content.url(event: event), total: total) {
    thread.lock()
    content.videoData = videoData
    content.isUploaded = true
    serverEvents.contentUploaded(event: event, content: content)
    thread.unlock()
  }
}

private func addChatFile(connection: Connection, data: DataReader) throws {
  let locker = thread.safeLocker
  locker.lock()
  let chat = try data.chat()
  let messageIndex: Int = try data.next()
  let bodyIndex: Int = try data.next()
  
  guard let message = chat[messageIndex] else { throw Response.messageNotFound }
  guard let body = message.storableMessage(at: bodyIndex) else { throw Response.messageNotFound }
  guard message.from == connection.user.id else { throw Response.chatPermissions }
  try body.uploadBody(data: data)
  let total = body.fileSize
  
  let url = body.url(message: message)
  locker.unlock()
  
  try connection.read(url, total: total) {
    thread.lock()
    body.isUploaded = true
    chat.uploaded(messageIndex: messageIndex, bodyIndex: bodyIndex)
    thread.unlock()
  }
}

private func addVideoPreview(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let photoid = try data.int()
  let total = try data.int64()
  
  try total.checkSize(max: .preview)
  let content = try event.video(id: photoid, by: connection.user)
  try content.check(author: connection)
  
  try connection.read(content.previewURL(event: event), total: total) {
    thread.lock()
    content.isPreviewUploaded = true
    serverEvents.contentPreviewUploaded(event: event, content: content)
    thread.unlock()
  }
}

private func getPhoto(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let photoid = try data.int()
  let content = try event.photo(id: photoid, by: connection.user)
  try connection.send(content.url(event: event), data: data)
}

private func getPhotoPreview(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let photoid = try data.int()
  let content = try event.photo(id: photoid, by: connection.user)
  try connection.send(content.previewURL(event: event), data: data)
}

private func getVideo(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let videoid = try data.int()
  let content = try event.video(id: videoid, by: connection.user)
  try connection.send(content.url(event: event), data: data)
}

private func getVideoPreview(connection: Connection, data: DataReader) throws {
  let event = try data.event()
  let videoid = try data.int()
  let content = try event.video(id: videoid, by: connection.user)
  try connection.send(content.previewURL(event: event), data: data)
}

private func getChatFile(connection: Connection, data: DataReader) throws {
  let locker = thread.safeLocker
  locker.lock()
  let chat = try data.chat()
  let index: Int = try data.next()
  let bodyIndex: Int = try data.next()
  guard chat.canRead(user: connection.user) else { throw Response.chatPermissions }
  guard chat.canDownload(user: connection.user) else { throw Response.chatPermissions }
  guard let message = chat[index] else { throw Response.messageNotFound }
  guard let body = message.storableMessage(at: bodyIndex) else { throw Response.messageNotFound }
  guard body.isUploaded else { throw Response.fileNotUploaded }
  let url = body.url(message: message)
  locker.unlock()
  try connection.send(url, data: data)
}

var cmdCpuTime = [cmd: UInt64]()
class SafeLocker {
  var isLocked = false
  var command: cmd
  var time: UInt64 = 0
  init(command: cmd) {
    self.command = command
  }
  func lock() {
    if isLocked {
      fatalError("deadlock debil)00")
    }
    thread.lock()
    isLocked = true
  }
  func unlock() {
    guard isLocked else { return }
    thread.unlock()
    isLocked = false
  }
  deinit {
    guard time > 0 else { return }
    cmdCpuTime[command]! += time
  }
}

private extension Event {
  func video(id: Int, by user: User) throws -> VideoContent {
    thread.lock()
    defer { thread.unlock() }
    guard let content = self.content[id] else { throw Response.contentNotFound }
    guard let video = content as? VideoContent else { throw Response.contentWrongType }
    return video
  }
  func photo(id: Int, by user: User) throws -> PhotoContent {
    thread.lock()
    defer { thread.unlock() }
    guard let content = self.content[id] else { throw Response.contentNotFound }
    guard let photo = content as? PhotoContent else { throw Response.contentWrongType }
    return photo
  }
}
private extension Content {
  func check(author connection: Connection) throws {
    guard author == connection.user.id else { throw Response.contentWrongAuthor }
  }
}

private extension Connection {
  
  /*
 download:
   
   send:
   ...
   offset
   
   receive:
   .ok
   size
   offset
   
   file
   
 upload:
   send:
   ...
   size
   
   receive:
   .ok
   offset
   
   send:
   file
   
 */
  
  func send(_ url: FileURL, data: DataReader) throws {
    let offset = try data.int64()
    guard offset >= 0 else { throw Response.wrongFileOffset }
    
    let file = NetFile(at: url)
    file.completed = offset
    file.prepare(for: .upload)
    
    guard file.total > 0 else { throw Response.wrongFileSize }
    response { data in
      data.append(Response.ok)
      data.append(file.total)
      data.append(file.completed)
    }
    try send(file)
//    try? disconnect()
  }
  func read(_ url: FileURL, total: Int64, completion: @escaping ()->()) throws {
    guard total > 0 else { throw Response.wrongFileSize }
    print("creating netfile")
    let file = NetFile(at: url)
    file.tempLocation = url.temp
    file.total = total
    file.prepare(for: .download)
    print("responding")
    response { data in
      data.append(Response.ok)
      data.append(file.completed)
    }
    print("receiving")
    try read(file, completion: completion)
//    try? disconnect()
  }
  
}
