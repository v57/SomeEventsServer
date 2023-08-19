//
//  UserReport.swift
//  Server
//
//  Created by Дмитрий Козлов on 12/17/17.
//

import Foundation
import SomeData
import SomeBridge

class UserReport: Report {
  let uid: ID
  let reason: UserRules
  var user: User { return users[uid]! }
  
  init(user: ID, reason: UserRules) {
    self.uid = user
    self.reason = reason
    super.init()
  }
  required init(data: DataReader) throws {
    uid = try data.next()
    reason = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(uid)
    data.append(reason)
    super.save(data: data)
  }
  override func write(body data: DataWriter) {
    data.append(uid)
    data.append(reason)
  }
  
  override var isProtected: Bool {
    return user.isProtected
  }
  override func protect() {
    user.isProtected = true
  }
  override func ban() {
    
  }
  override var type: ReportType {
    return .user
  }
  override var description: String {
    return "(reason: \(reason), user: \(uid.userName))"
  }
}
