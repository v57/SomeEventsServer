//
//  push.swift
//  Server
//
//  Created by Дмитрий Козлов on 7/1/17.
//

import Foundation
import PerfectNotifications
import SomeFunctions
import SomeData
import SomeBridge

enum PushNotification {
  case text(String?,String?)
  case friendRequest(User)
  case newEvent(User,Event)
  case invite(User,Event)
  case comment(Event,Message)
  
  private func array(title: String?, subtitle: String?) -> [APNSNotificationItem] {
    var items = [APNSNotificationItem]()
    if let title = title {
      items.append(.alertTitle(title))
    }
    if let subtitle = subtitle {
      items.append(.alertBody(subtitle))
    }
    return items
  }
  var items: [APNSNotificationItem] {
    var items: [APNSNotificationItem]
    var writer: DataWriter!
    switch self {
    case .text(let title, let subtitle):
      items = array(title: title, subtitle: subtitle)
    case .friendRequest(let user):
      items = array(title: user.name, subtitle: "Wants to be your friend")
      writer = DataWriter()
      writer.append(PushType.friends)
    case .newEvent(let user,let event):
      items = array(title: user.name, subtitle: "Started \(event.name)")
      writer = DataWriter()
      writer.append(PushType.event)
      event.eventMain(data: writer)
    case .invite(let user, let event):
      items = array(title: user.name, subtitle: "Invited you to \(event.name)")
      writer = DataWriter()
      writer.append(PushType.event)
      event.eventMain(data: writer)
    case .comment(let event, let message):
      items = array(title: event.name, subtitle: message.description)
      writer = DataWriter()
      writer.append(PushType.comments)
      event.eventMain(data: writer)
    }
    if let writer = writer {
      writer.encrypt(password: 0xb46c5f92427dd8e1)
      items.append(.customPayload("d",writer.base64))
    }
    return items
  }
}

class PushManager: ServerManager, CustomPath {
  let fileName = "push.db"
  // your app id. we use this as the configuration name, but they do not have to match
  let appid = "ru.kozlov.some"
  
  let keyId = "SY7J67VFPX"
  let teamId = "AUCR797TMH"
  let keyURL = "data/key.p8".dbURL
  let installed: Bool
  
  var data = [String: Int]()
  
  override init() {
    installed = keyURL.exists
    if installed {
      print("push: enabled")
    } else {
      print("push: disabled")
    }
    super.init()
    guard installed else { return }
    NotificationPusher.addConfigurationAPNS(name: appid, production: true, keyId: keyId, teamId: teamId, privateKeyPath: keyURL.path)
  }
  
  func pushAll(notification: PushNotification) {
    let tokens = Set(data.keys)
    push(notification: notification, to: tokens)
  }
  
  func push(to users: [User], notification: PushNotification) {
    var tokens = Set<String>()
    for user in users {
      tokens += user.tokens
    }
    push(notification: notification, to: tokens)
  }
  
  func push(to user: User, notification: PushNotification) {
    push(notification: notification, to: user.tokens)
  }
  
  func push(notification: PushNotification, to tokens: Set<String>) {
    guard installed else { return }
    guard !tokens.isEmpty else { return }
    let pusher = NotificationPusher(apnsTopic: appid)
    pusher.pushAPNS(configurationName: appid, deviceTokens: Array(tokens), notificationItems: notification.items) { responses in
      for response in responses {
        print(response)
      }
    }
  }
  
  func add(token: String, to user: User) {
    if let id = data[token] {
      if id == user.id {
        return
      } else {
        users[id].tokens.remove(token)
        data[token] = user.id
        user.tokens.insert(token)
      }
    } else {
      data[token] = user.id
      user.tokens.insert(token)
    }
  }
  
  func remove(token: String) {
    guard let id = data[token] else { return }
    data[token] = nil
    guard let user = users[id] else { return }
    user.tokens.remove(token)
  }
  
  func remove(token: String, from user: User) {
    guard let id = data[token] else { return }
    guard user.id == id else { return }
    user.tokens.remove(token)
    data[token] = nil
  }
  
  private func move(token: String, to user: User) {
    guard let id = data[token] else { return }
    guard id != user.id else { return }
    data[token] = nil
    user.tokens.remove(token)
  }
  
  func save(data: DataWriter) throws {
    data.append(self.data.count)
    for (token,id) in self.data {
      data.append(token)
      data.append(id)
    }
  }
  func load(data: DataReader) throws {
    let count = try data.int()
    for _ in 0..<count {
      let token = try data.string()
      let id = try data.int()
      self.data[token] = id
      users[id].tokens.insert(token)
    }
  }
  
//  let reader: InputStream
//  let writer: OutputStream
//  var buffer = [UInt8](repeating: 0, count: 2048)
//
//  override init() {
//    // dev: gateway.sandbox.push.apple.com
//    // release: gateway.push.apple.com
//    let url = "gateway.sandbox.push.apple.com" as CFString
//    let port: UInt32 = 2195
//
//    var cfreader: Unmanaged<CFReadStream>?
//    var cfwriter: Unmanaged<CFWriteStream>?
//
//    CFStreamCreatePairWithSocketToHost(nil, url, port, &cfreader, &cfwriter)
//
//    reader = cfreader!.takeUnretainedValue()
//    writer = cfwriter!.takeUnretainedValue()
//
//    super.init()
//
//    reader.setProperty(StreamSocketSecurityLevel.tlSv1, forKey: .socketSecurityLevelKey)
//    reader.setProperty(<#T##property: Any?##Any?#>, forKey: .)
//
//    reader.delegate = self
//    writer.delegate = self
//
//    reader.schedule(in: .current, forMode: .defaultRunLoopMode)
//    writer.schedule(in: .current, forMode: .defaultRunLoopMode)
//
//    reader.open()
//    writer.open()
//  }
//
//  func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
//    switch eventCode {
//    case .openCompleted:
//      print("push: connected")
//    case .hasBytesAvailable:
//      inputStream.read(&buffer, maxLength: buffer.count)
//      while inputStream.hasBytesAvailable {
//        _ = inputStream.read(&buffer, maxLength: buffer.count)
//        let str = String(bytes: buffer, encoding: String.Encoding.utf8)
//        print(" \(str)")
//
//      }
//    default:
//
//    }
//  }
//
//  func connect() {
//
//  }
//
//  static func print(_ string: String) {
//
//  }
}
