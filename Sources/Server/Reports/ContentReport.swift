//
//  ContentReport.swift
//  Server
//
//  Created by Дмитрий Козлов on 12/17/17.
//

import Foundation
import SomeData
import SomeBridge

class ContentReport: Report {
  let cid: ID2
  let reason: ContentRules
  var event: Event {
    return cid.x.event
  }
  var content: Content {
    return try! cid.content()
  }
  
  init(cid: ID2, reason: ContentRules) {
    self.cid = cid
    self.reason = reason
    super.init()
  }
  required init(data: DataReader) throws {
    cid = try data.next()
    reason = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(cid)
    data.append(reason)
    super.save(data: data)
  }
  
  override func write(body data: DataWriter) {
    data.append(cid)
    data.append(reason)
  }
  
  
  override var isProtected: Bool {
    return content.isProtected
  }
  override func protect() {
    content.isProtected = true
  }
  override func ban() {
    let content = self.content
    let event = self.event
    try? event.remove(content: content.id, by: content.author.user!, notify: true)
  }
  override var type: ReportType {
    return .content
  }
  override var description: String {
    if let link = (content as? PhysicalContent)?.link(event: event) {
      return "(reason: \(reason), content: \(link))"
    } else {
      return "(reason: \(reason), event: \(cid.x), content: \(cid.y))"
    }
  }
}
