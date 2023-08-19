//
//  CommentReport.swift
//  Server
//
//  Created by Дмитрий Козлов on 12/17/17.
//

import Foundation
import SomeData
import SomeBridge

class CommentReport: Report {
  let mid: ID2
  let reason: CommentRules
  var event: Event {
    return mid.x.event
  }
  var message: Message {
    return try! mid.comment()
  }
  
  init(mid: ID2, reason: CommentRules) {
    self.mid = mid
    self.reason = reason
    super.init()
  }
  required init(data: DataReader) throws {
    mid = try data.next()
    reason = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(mid)
    data.append(reason)
    super.save(data: data)
  }
  override func write(body data: DataWriter) {
    data.append(mid)
    data.append(reason)
  }
  
  override var isProtected: Bool {
    return message.isProtected
  }
  override func protect() {
    message.isProtected = true
  }
  override func ban() {
    let event = self.event
    event.comments.delete(at: mid.y)
  }
  override var type: ReportType {
    return .comment
  }
  override var description: String {
    return "(reason: \(reason), comment: \(message.description))"
  }
}
