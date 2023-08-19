//
//  Messages.swift
//  SomeBridge
//
//  Created by Дмитрий Козлов on 11/29/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import SomeData

extension Response {
  public func check() throws {
    guard self == .ok else { throw self }
  }
}

