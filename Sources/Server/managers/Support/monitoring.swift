//
//  info.swift
//  faggot-server
//
//  Created by Дмитрий Козлов on 12/6/16.
//  Copyright © 2016 Dmitry Kozlov. All rights reserved.
//

import Foundation
import SomeFunctions

class Monitor: ServerManager {
  
  var cpu = 0.0
  var mem = 0
  
  var storage = 0
  
  
  var downloads = 0
  var totalDownloads = 0
  var uploads = 0
  var totalUploads = 0
  
  var events = 0
  var users = 0
  
  
  func userRegistered() {
    users += 1
  }
  
  func eventCreated() {
    events += 1
  }
  
  func eventDeleted() {
    events -= 1
  }
  
  func uploadStarted() {
    uploads += 1
    totalUploads += 1
  }
  
  func uploadEnded() {
    uploads -= 1
  }
  
  func downloadStarted() {
    downloads += 1
    totalDownloads += 1
  }
  
  func downloadEnded() {
    downloads -= 1
  }
  
  func recalculate() {
//    storage = Int(du_s(""))
  }
  
}
