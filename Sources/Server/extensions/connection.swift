//
//  connection.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 17/05/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions
import SomeData
//-import SomeTcp

private extension Time {
  var ago: String {
    if self == 0 {
      return "-"
    } else {
      return "\(Time.now - self) sec"
    }
  }
}

private extension Time {
  static func ping(_ start: Double) -> Int {
    return Int((Time.abs - start) * 1000)
  }
}

//private extension Int {
//  var bytesString: String {
//    if self < 1.kb {
//      return "\(self) bytes"
//    } else if self < 1.mb {
//      return "\(self.toKB) KB"
//    } else {
//      return "\(self.toMB) MB"
//    }
//  }
//}






















