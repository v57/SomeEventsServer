//
//  storage.swift
//  SomeFunctions
//
//  Created by Дмитрий Козлов on 10/29/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

#if os(iOS)
  
  extension SomeSettings {
    public static var debugStorage: Bool = false
  }
  private func print(_ items: Any...) {
    guard SomeSettings.debugStorage else { return }
    Swift.print(items)
  }

private func isEqual<T: Comparable>(_ a: T?, _ b: T?) -> Bool {
  guard let a = a else { return b == nil }
  guard let b = b else { return false }
  return a == b
}
  
  public enum iCloudUpdateType: Int {
    case remote
    case synced
    case quotaViolation
    case accountChanged
    public init?(rawValue: Int) {
      switch rawValue {
      case NSUbiquitousKeyValueStoreServerChange:
        self = .remote
      case NSUbiquitousKeyValueStoreInitialSyncChange:
        self = .synced
      case NSUbiquitousKeyValueStoreQuotaViolationChange:
        self = .quotaViolation
      case NSUbiquitousKeyValueStoreAccountChange:
        self = .accountChanged
      default:
        return nil
      }
    }
  }
  
public enum StorageError: Error {
  case notFound
}
public class Storage {
  public var onUpdate: ((_ key: String, _ value: Any?)->())?
  public var localStorage: UserDefaults
  public var cloudStorage: NSUbiquitousKeyValueStore = .default
  
  public var cloudKeys = Set<String>()
  public var localKeys = Set<String>()
  
  private var observer: Any?
  public var synced = false
  
  private var firstSyncWaiters = [()->()]()
  private func firstSynced() {
    guard !synced else { return }
    assert(Thread.current.isMainThread)
    synced = true
    firstSyncWaiters.forEach { $0() }
    firstSyncWaiters.removeAll()
  }
  public func onFirstSync(action: @escaping ()->()) {
    if synced {
      action()
    } else {
      firstSyncWaiters.append(action)
    }
  }
  
  public init(appGroup: String = "") {
    if appGroup.isEmpty {
      localStorage = .standard
    } else {
      if let localStorage = UserDefaults(suiteName: appGroup) {
        self.localStorage = localStorage
        let dictionary = cloudStorage.dictionaryRepresentation
        for (key,value) in dictionary {
          if localStorage.object(forKey: key) == nil {
            localStorage.set(value, forKey: key)
          }
        }
      } else {
        print("storage error: cannot create user defaults with group \(appGroup)")
        self.localStorage = .standard
      }
    }
    register()
  }
  deinit {
    unregister()
  }
  
  public func object<T>(for key: String) throws -> T {
    var value: T?
    if let retv = cloudStorage.object(forKey: key) {
      value = retv as? T
    } else if let retv = localStorage.object(forKey: key) {
      if !localKeys.contains(key) {
        cloudStorage.set(retv, forKey: key)
      }
      value = retv as? T
    }
    if let value = value {
      return value
    } else {
      throw StorageError.notFound
    }
  }
  public func update(block: ()->()) {
    block()
    syncronize()
  }
  public func set(object: Any, for key: String) {
    if !localKeys.contains(key) {
      cloudStorage.set(object, forKey: key)
    }
    if !cloudKeys.contains(key) {
      localStorage.set(object, forKey: key)
    }
  }
  public func remove(_ key: String) {
    if !localKeys.contains(key) {
      cloudStorage.removeObject(forKey: key)
    }
    if !cloudKeys.contains(key) {
      localStorage.removeObject(forKey: key)
    }
  }
  public func syncronize() {
    let cSynced = cloudStorage.synchronize()
    let lSynced = localStorage.synchronize()
    if !cSynced {
      print("icloud: syncronize failed")
    }
    if !lSynced {
      print("keychain: syncronize failed")
    }
  }
  func received(notification: Notification) {
    print("icloud: received notification \(notification.userInfo ?? [:])")
    guard let userInfo = notification.userInfo else { return }
    guard let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey]
      else { return }
    guard let reason = reasonForChange as? Int else { return }
    guard let type = iCloudUpdateType(rawValue: reason) else { return }
    guard type == .remote || type == .synced else { return }
    firstSynced()
    
    guard let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
    
    for key in changedKeys {
      let value = self.cloudStorage.object(forKey: key)
      if !cloudKeys.contains(key) {
        self.localStorage.set(value, forKey: key)
      }
      onUpdate?(key,value)
    }
  }
  func register() {
    observer = NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloudStorage, queue: nil) { [weak self] notification in
      self?.received(notification: notification)
    }
  }
  func unregister() {
    guard let observer = observer else { return }
    NotificationCenter.default.removeObserver(observer)
    self.observer = nil
  }
}

#endif
