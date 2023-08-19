//
//  trash.swift
//  Server
//
//  Created by Дмитрий Козлов on 12/16/17.
//

import Foundation
import SomeFunctions
import SomeData

class Trash: ServerManager, CustomPath {
  let fileName = "trash.db"
  var events = [Int]()
  var users = [Int]()
  
  func save(data: DataWriter) throws {
    
  }
  func load(data: DataReader) throws {
    
  }
}
