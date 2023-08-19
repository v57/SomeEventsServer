//
//  EventReport.swift
//  Server
//
//  Created by Дмитрий Козлов on 12/17/17.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

class EventReport: Report {
  let eid: ID
  let reason: EventRules
  var event: Event { return events[eid]! }
  
  init(event: ID, reason: EventRules) {
    self.eid = event
    self.reason = reason
    super.init()
  }
  required init(data: DataReader) throws {
    eid = try data.next()
    reason = try data.next()
    try super.init(data: data)
  }
  override func save(data: DataWriter) {
    data.append(eid)
    data.append(reason)
    super.save(data: data)
  }
  override func write(body data: DataWriter) {
    data.append(eid)
    data.append(reason)
  }
  
  
  override var isProtected: Bool {
    return event.isProtected
  }
  override func ban() {
    thread.lock()
    event.isBanned = true
    event.set(privacy: .private, notify: true)
    thread.unlock()
  }
  override func protect() {
    event.isProtected = true
  }
  override var type: ReportType {
    return .event
  }
  override var description: String {
    return "(reason: \(reason), event: \(event.id) \(event.name))"
  }
}
