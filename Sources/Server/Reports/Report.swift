//
//  Report.swift
//  Server
//
//  Created by Дмитрий Козлов on 12/17/17.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge

extension ReportType {
  var classType: Report.Type {
    switch self {
    case .user:
      return UserReport.self
    case .event:
      return EventReport.self
    case .content:
      return ContentReport.self
    case .comment:
      return CommentReport.self
    }
  }
  static let all = Options<ReportType,UInt8>(rawValue: .max)
}

class Report: DataRepresentable, Hashable, Versionable, CustomStringConvertible {
  static var version = 0
  let id: ID
  var from = Set<Int>()
  var accepted = Set<Int>()
  var declined = Set<Int>()
  init() {
    self.id = .report
  }
  required init(data: DataReader) throws {
    id = try data.next()
    from = try data.next()
    accepted = try data.next()
    declined = try data.next()
  }
  func save(data: DataWriter) {
    data.append(id)
    data.append(from)
    data.append(accepted)
    data.append(declined)
  }
  func write(body data: DataWriter) {
    
  }
  func preview(body data: DataWriter) {
    data.append(type)
    data.append(id)
    data.append(from.count)
    data.append(accepted.count)
    data.append(declined.count)
    write(body: data)
  }
  var isChecked: Bool {
    return !accepted.isEmpty || !declined.isEmpty
  }
  var isAccepted: Bool {
    return !accepted.isEmpty
  }
  var isDeclined: Bool {
    return !declined.isEmpty
  }
  var isProtected: Bool {
    fatalError()
  }
  func protect() {
    fatalError()
  }
  func ban() {
    fatalError()
  }
  var type: ReportType {
    fatalError()
  }
  
  var hashValue: Int {
    return id.hashValue
  }
  static func ==(lhs: Report, rhs: Report) -> Bool {
    return lhs.id == rhs.id
  }
  
  var description: String {
    return "some report"
  }
}
