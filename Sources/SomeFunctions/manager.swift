//
//  manager.swift
//  SomeFunctions
//
//  Created by Дмитрий Козлов on 28/07/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation

public protocol Manager: class {
  func start()
  func pause()
  func resume()
  func close()
  func login()
  func logout()
  func reload()
  func memoryWarning()
}

extension Manager {
  public func start() {}
  public func pause() {}
  public func resume() {}
  public func close() {}
  public func login() {}
  public func logout() {}
  public func reload() {}
  public func memoryWarning() {}
}
