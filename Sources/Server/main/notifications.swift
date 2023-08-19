//
//  server-events.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 12/8/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp
import SomeBridge

let serverEvents = ServerEvents()
class ServerEvents {
  
  // Системное сообщение
  func systemMessage(text: String, to clients: Set<Connection>) { // не подключено
    let data = spammer()
    data.append(subcmd.systemMessage)
    data.append(text)
    spam(data: data, to: clients)
  }
  
  func avatarChanged(user: User) {
    let data = spammer()
    data.append(subcmd.pAvatarChanged)
    data.append(user.id)
    data.append(user.avatarVersion)
    data.append(user.mainVersion)
    spam(data: data, to: user.profileConnections + user.currentConnections)
  }
  func avatarRemoved(user: User) {
    let data = spammer()
    data.append(subcmd.pAvatarRemoved)
    data.append(user.id)
    data.append(user.mainVersion)
    spam(data: data, to: user.profileConnections + user.currentConnections)
  }
  func friendAdded(user: User, friend: User) {
    let data = spammer()
    data.append(subcmd.friendAdded)
    data.append(friend.id)
    data.append(user.privateProfileVersion)
    spam(data: data, to: user.currentConnections)
  }
  func friendRemoved(user: User, friend: User) {
    let data = spammer()
    data.append(subcmd.friendRemoved)
    data.append(friend.id)
    data.append(user.privateProfileVersion)
    spam(data: data, to: user.currentConnections)
  }
  func incomingAdded(user: User, friend: User) {
    let data = spammer()
    data.append(subcmd.incomingAdded)
    data.append(friend.id)
    data.append(user.privateProfileVersion)
    spam(data: data, to: user.currentConnections)
    if friend.incoming.count < 20 {
      user.push(.friendRequest(friend))
    }
  }
  func outcomingAdded(user: User, friend: User) {
    let data = spammer()
    data.append(subcmd.outcomingAdded)
    data.append(friend.id)
    data.append(user.privateProfileVersion)
    spam(data: data, to: user.currentConnections)
  }
  
  // Новый подписчик
  func subscribed(user: User, subscriber: User) {
    let data = spammer()
    data.append(subcmd.pSubs)
    data.append(user.subscribers.count)
    
    spam(data: data, to: user.profileConnections + user.currentConnections)
  }
  func unsubscribed(user: User, subscriber: User) {
    let data = spammer()
    data.append(subcmd.pSubs)
    data.append(user.subscribers.count)
    
    spam(data: data, to: user.profileConnections + user.currentConnections)
  }
  
  // Приглашение в событие
  func invite(event: Event, user: User, by: User) {
    let s = spammer()
    s.append(subcmd.eInvited)
    event.eventMain(data: s)
    s.append(user.id)
    s.append(user.publicProfileVersion)
    spam(data: s, to: user.currentConnections + user.profileConnections + event.subs)
    user.push(.invite(by, event))
  }
  
  func uninvite(event: Event, user: User) {
    let s = spammer()
    s.append(subcmd.eUninvited)
    s.append(event.id)
    s.append(user.id)
    s.append(user.publicProfileVersion)
    spam(data: s, to: user.currentConnections + user.profileConnections + event.subs)
  }
  
  func rename(user: User, name: String) {
    let s = spammer()
    s.append(subcmd.pName)
    s.append(user.id)
    s.append(name)
    s.append(user.mainVersion)
    spam(data: s, to: user.currentConnections + user.profileConnections)
  }
  
  // - Событие:
  func ownerChanged(event: Event) {
    let d = spammer()
    d.append(subcmd.eNewOwner)
    d.append(event.id)
    d.append(event.previewVersion)
    d.append(event.owner)
    spam(data: d, to: users[event.owner].currentConnections)
  }
  
  // Событие завершено
  func eventStatus(event: Event) {
    let status = event._status
    let s = spammer()
    s.append(subcmd.eStatus)
    s.append(event.id)
    s.append(event.previewVersion)
    s.append(event._status)
    
    if status == .ended {
      s.append(event.endTime)
    } else if status == .started {
      s.append(event.startTime)
      s.append(event.endTime)
    }
    var subs = event.subs
    for user in event.invited.users {
      subs += user.currentConnections
      subs += user.profileConnections
    }
    spam(data: s, to: subs)
  }
  
  // Приватность изменена
  func eventPrivacy(event: Event) { // не подключено
    let s = spammer()
    s.append(subcmd.ePrivate)
    s.append(event.id)
    s.append(event.previewVersion)
    s.append(event.privacy)
    var subs = event.subs
    for user in event.invited.users {
      subs += user.currentConnections
      subs += user.profileConnections
    }
    spam(data: s, to: subs)
  }
  // Событие передвинуто
  func eventMoved(event: Event) {
    let s = spammer()
    s.append(subcmd.eMoved)
    s.append(event.id)
    s.append(event.previewVersion)
    s.append(event.lat)
    s.append(event.lon)
    s.append(event.options)
    var subs = event.subs
    for user in event.invited.users {
      subs += user.currentConnections
      subs += user.profileConnections
    }
    spam(data: s, to: subs)
  }
  // Время события изменено
  func eventTimeChanged(event: Event) { // не подключено
    let s = spammer()
    s.append(subcmd.eTimeChanged)
    s.append(event.id)
    s.append(event.previewVersion)
    s.append(event.startTime)
    s.append(event.endTime)
    var subs = event.subs
    for user in event.invited.users {
      subs += user.currentConnections
      subs += user.profileConnections
    }
    spam(data: s, to: subs)
  }
  // Комменты включены/отключены
  func ecEnabled(event: Event) { // не подключено
    let s = spammer()
    s.append(subcmd.ecEnabled)
    s.append(event.id)
    s.append(event.comments.isEnabled)
    var subs = event.subs
    subs += event.comments.subscribers
    spam(data: s, to: subs)
  }
  
  // Новый контент
  func newContent(event: Event, content: Content, ignore: Connection?) {
    let data = spammer()
    data.append(subcmd.eNewContent)
    data.append(event.id)
    data.append(content.type)
    data.append(content)
    var subs = event.subs
    if let ignore = ignore {
      subs.remove(ignore)
    }
    spam(data: data, to: subs)
  }
  // Превью контента загружено
  func contentPreviewUploaded(event: Event, content: Content) {
    let data = spammer()
    data.append(subcmd.eContentPreviewLoaded)
    data.append(event.id)
    data.append(content.id)
    
    spam(data: data, to: event.subs)
    if let last = event.lastContent {
      if last.time < content.time {
        event.set(preview: content)
        self.previewChanged(event: event, content: content)
      }
    } else {
      event.set(preview: content)
      self.previewChanged(event: event, content: content)
    }
  }
  // Сам контент загружен
  func contentUploaded(event: Event, content: Content) {
    let data = spammer()
    data.append(subcmd.eContentLoaded)
    data.append(event.id)
    data.append(content.id)
    data.append(content.type)
    if let photo = content as? PhotoContent {
      data.append(photo.photoData)
    } else if let video = content as? VideoContent {
      data.append(video.videoData)
    }
    spam(data: data, to: event.subs)
  }
  // Контент удалён
  func contentRemoved(event: Event, content: Content) {
    let data = spammer()
    data.append(subcmd.eContentRemoved)
    data.append(event.id)
    data.append(content.id)
    spam(data: data, to: event.subs)
  }
  
  // Событие переименовано
  func eventRenamed(event: Event) {
    let s = spammer()
    s.append(subcmd.eName)
    s.append(event.id)
    s.append(event.previewVersion)
    s.append(event.name)
    var subs = event.subs
    for user in event.invited.users {
      subs += user.currentConnections
      subs += user.profileConnections
    }
    spam(data: s, to: subs)
  }
  
  // Количество просмотров
  func eventCurrent(event: Event) {
    let data = spammer()
    data.append(subcmd.eCurrent)
    data.append(event.id)
    data.append(event.current)
    spam(data: data, to: event.subs)
  }
  
  func eventViews(event: Event) {
    let data = spammer()
    data.append(subcmd.eViews)
    data.append(event.id)
    data.append(event.views)
    spam(data: data, to: event.subs)
  }
  
  // Количество текущих просмотров
  
  // Количест
  
  // - Карта:
  // Новое событие
  func mapInsert(event: Event, to connections: Set<Connection>) {
    let data = spammer()
    data.append(subcmd.mAddEvent)
    event.eventMain(data: data)
    spam(data: data, to: connections)
  }
  // Событие удалено
  func mapRemove(event: Event, to connections: Set<Connection>) {
    let data = spammer()
    data.append(subcmd.mRemoveEvent)
    data.append(event.id)
    spam(data: data, to: connections)
  }
  
  
  // Уведомления:
  // - Пользователь
  // Имя
  func nameChanged() { // не подключено
    
  }
  // Количество подписчиков
  func subsChanged() { // не подключено
    
  }
  // - События
  // Добавление событий
  func eventCreated(event: Event, by user: User) {
    let d = spammer()
    d.append(subcmd.pNewEvent)
    d.append(user.id)
    d.append(user.publicProfileVersion)
    event.eventMain(data: d)
    
    var connections = user.profileConnections + user.currentConnections
    if event.privacy < .subscribers {
      let friends = user.friends.users
      for friend in friends {
        connections += friend.currentConnections
      }
      friends.push(.newEvent(user, event))
    }
    spam(data: d, to: connections)
  }
  // Удаление событий
  // Смена названия
  // Последнее фото
  func previewChanged(event: Event, content: Content) {
    let data = spammer()
    data.append(subcmd.pEventPreviewChanged)
    data.append(event.id)
    data.append(event.previewVersion)
    data.append(content.type)
    data.append(content.id)
    
    var subs = Set<Connection>()
    for user in event.invited.users {
      subs += user.currentConnections
      subs += user.profileConnections
    }
    spam(data: data, to: subs)
  }
  func previewRemoved(event: Event) {
    let data = spammer()
    data.append(subcmd.pEventPreviewRemoved)
    data.append(event.id)
    data.append(event.previewVersion)
    
    var subs = Set<Connection>()
    for user in event.invited.users {
      subs += user.currentConnections
      subs += user.profileConnections
    }
    spam(data: data, to: subs)
  }
  
  // Статус события
  
  
  // Уведомления:
  // Пользователь пишет
  func typing() { // не подключено
    
  }
}
