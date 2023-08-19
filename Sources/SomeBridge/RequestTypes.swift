//
//  Requests.swift
//  SomeBridge
//
//  Created by Дмитрий Козлов on 11/29/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

public extension UInt8 {
  var ccmd: cmd? {
    return cmd(rawValue: self)
  }
  var scmd: subcmd? {
    return subcmd(rawValue: self)
  }
  var message: Response? {
    return Response(rawValue: self)
  }
}

