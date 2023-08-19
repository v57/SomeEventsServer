//
//  dictionary.swift
//  SomeFunctions
//
//  Created by Дмитрий Козлов on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

public func +=<K, V> (left: inout [K : V], right: [K : V]) {
  for (k, v) in right {
    left[k] = v
  }
}
extension Dictionary {
  public var any: Value {
    return Array(self.values).any
  }
}
