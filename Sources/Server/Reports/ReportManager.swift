//
//  reports.swift
//  Server
//
//  Created by Дмитрий Козлов on 10/30/17.
//

import Foundation
import SomeFunctions
import SomeData
import SomeBridge
//-import SomeTcp

extension ID {
  static var report: ID {
    return reports.counter.next()
  }
}

class ReportsManager: ServerManager, CustomPath, CounterManager {
  var counter = Counter<ID>()
  let fileName = "reports.db"
  var reports = [Int: Report]()
  var unchecked = [Int: Report]()
  
  var userReports = [ID: Report]()
  var eventReports = [ID: Report]()
  var contentReports = [ID2: Report]()
  var commentReports = [ID2: Report]()
  
  var count = 0
  var uncheckedCount = 0
  
  var subscribers = Set<Connection>()
  
  subscript(id: ID) -> Report? {
    return reports[id]
  }
  func check(report: Report) {
    unchecked[report.id] = nil
    uncheckedCount -= report.from.count
    count -= 1
    reportsAvailable()
  }
  func accept(id: ID, by user: User) {
    guard let report = reports[id] else { return }
    let users = report.from.users
    for user in users {
      user.privateProfileVersion.increment()
      user.reports.remove(report)
      user.reportsAccepted = user.reportsAccepted &+ 1
    }
    reportRemoved(report: report, accepted: true, for: users)
    check(report: report)
  }
  func decline(id: ID, by user: User) {
    guard let report = reports[id] else { return }
    report.protect()
    let users = report.from.users
    for user in users {
      user.privateProfileVersion.increment()
      user.reports.remove(report)
      user.reportsDeclined = user.reportsDeclined &+ 1
    }
    reportRemoved(report: report, accepted: false, for: users)
    check(report: report)
  }
  func reports(count: Int) -> [Report] {
    var reports = [Report]()
    for (_,report) in unchecked {
      guard reports.count < count else { break }
      reports.append(report)
    }
    return reports
  }
  func reports(with options: Options<ReportType,UInt8>, count: Int) -> [Report] {
    var reports = [Report]()
    for (_,report) in unchecked {
      guard reports.count < count else { break }
      guard options.contains(report.type) else { continue }
      reports.append(report)
    }
    return reports
  }
}

// MARK:- AuthCommands
extension ReportsManager: AuthCommands {
  func auth(commands: inout [cmd : ServerFunction]) {
    commands[.report] = report
  }
  private func report(connection: Connection, data: DataReader) throws {
    guard connection.user.allowReports else { return }
    let from = connection.user!
    let type: ReportType = try data.next()
    let report: Report
    var isCreated = false
    print("received report \(type)")
    switch type {
    case .user:
      let user = try data.user()
      let reason: UserRules = try data.next()
      if let r = userReports[user.id] {
        report = r
      } else {
        report = UserReport(user: user.id, reason: reason)
        guard !report.isProtected else { return }
        isCreated = true
        userReports[user.id] = report
      }
    case .event:
      let event = try data.event()
      let reason: EventRules = try data.next()
      if let r = eventReports[event.id] {
        report = r
      } else {
        report = EventReport(event: event.id, reason: reason)
        guard !report.isProtected else { return }
        isCreated = true
        eventReports[event.id] = report
      }
    case .content:
      let cid: ID2 = try data.next()
      try cid.content()
      let reason: ContentRules = try data.next()
      if let r = contentReports[cid] {
        report = r
      } else {
        report = ContentReport(cid: cid, reason: reason)
        guard !report.isProtected else { return }
        isCreated = true
        contentReports[cid] = report
      }
    case .comment:
      let mid: ID2 = try data.next()
      try mid.comment()
      let reason: CommentRules = try data.next()
      if let r = contentReports[mid] {
        report = r
      } else {
        report = CommentReport(mid: mid, reason: reason)
        guard !report.isProtected else { return }
        isCreated = true
        commentReports[mid] = report
      }
    }
    
    if isCreated {
      reports[report.id] = report
      unchecked[report.id] = report
      count += 1
    } else {
      guard !report.from.contains(from.id) else { return }
    }
    uncheckedCount += 1
    from.reports.insert(report)
    from.privateProfileVersion.increment()
    report.from.insert(from.id)
    reportSent(report: report, by: connection)
    admins.received(report: report)
    reportsAvailable()
  }
}

extension ReportsManager: ModeratorCommands {
  func moderator(commands: inout [cmd : ServerFunction]) {
    commands[.reports] = reports
    commands[.acceptReport] = acceptReport
    commands[.declineReport] = declineReport
  }
  
  private func reports(connection: Connection, data: DataReader) throws {
    let options: Options<ReportType,UInt8> = try data.next()
    let count: Int = try data.next()
    thread.lock()
    let array = reports(with: options, count: count)
    thread.unlock()
    connection.response { data in
      data.append(array.count)
      for report in array {
        data.append(report.type)
        data.append(report.id)
        report.write(body: data)
        data.append(report.from.count)
        data.append(report.accepted.count)
        data.append(report.declined.count)
      }
    }
  }
  
  private func acceptReport(connection: Connection, data: DataReader) throws {
//    let type: ReportType = try data.next()
    let id: ID = try data.next()
    thread.lock()
    accept(id: id, by: connection.user)
    thread.unlock()
  }
  private func declineReport(connection: Connection, data: DataReader) throws {
//    let type: ReportType = try data.next()
    let id: ID = try data.next()
    thread.lock()
    decline(id: id, by: connection.user)
    thread.unlock()
  }
}

// MARK:- Notifications
extension ReportsManager {
  // user notifications
  func reportSent(report: Report, by connection: Connection) {
    let data = spammer()
    data.append(subcmd.reportSent)
    data.append(report.type)
//    data.append(report.id)
    report.write(body: data)
    var connections = connection.user.currentConnections
    connections.remove(connection)
    spam(data: data, to: connections)
  }
  func reportRemoved(report: Report, accepted: Bool, for users: [User]) {
    let data = spammer()
    data.append(subcmd.reportRemoved)
    data.append(accepted)
    data.append(report.type)
    data.append(report.id)
    report.write(body: data)
    var connections = [Connection]()
    for user in users {
      connections += user.currentConnections
    }
    spam(data: data, to: connections)
  }
  
  // moderator notifications
  func reportsAvailable() {
    let data = spammer()
    data.append(subcmd.reportAvailable)
    data.append(count)
    data.append(uncheckedCount)
    spam(data: data, to: moderators.connections)
  }
  
  // subscription notifications
  func accepted(report: Report) {
    let data = spammer()
    data.append(subcmd.newReport)
    data.append(count)
    data.append(uncheckedCount)
    data.append(report.id)
    spam(data: data, to: subscribers)
  }
  func received(report: Report) {
    let data = spammer()
    data.append(subcmd.newReport)
    data.append(count)
    data.append(uncheckedCount)
    report.preview(body: data)
    spam(data: data, to: subscribers)
  }
}

// MARK:- DataRepresentable
extension ReportsManager {
  func save(data: DataWriter) {
    data.append(count)
    data.append(uncheckedCount)
    data.append(reports.count)
    for report in reports.values {
      data.append(report.type)
      data.append(report)
    }
  }
  func load(data: DataReader) throws {
    self.count = try data.int()
    self.uncheckedCount = try data.int()
    let count = try data.int()
    for _ in 0..<count {
      let type: ReportType = try data.next()
      let report: Report
      switch type {
      case .user:
        let userReport: UserReport = try data.next()
        userReports[userReport.uid] = userReport
        report = userReport
      case .event:
        let eventReport: EventReport = try data.next()
        eventReports[eventReport.eid] = eventReport
        report = eventReport
      case .content:
        let contentReport: ContentReport = try data.next()
        contentReports[contentReport.cid] = contentReport
        report = contentReport
      case .comment:
        let commentReport: CommentReport = try data.next()
        commentReports[commentReport.mid] = commentReport
        report = commentReport
      }
      reports[report.id] = report
      if !report.isChecked {
        unchecked[report.id] = report
      }
      for id in report.from {
        id.user!.reports.insert(report)
      }
    }
  }
}

// MARK:- Terminal
extension ReportsManager: TerminalCommands {
  func addCommands() {
    terminal.add(function: "reports") {
      print("reports:",self.reports.count)
      print("unchecked:",self.unchecked.count)
      print()
      print("user reports:",self.userReports.count)
      print("event reports:",self.eventReports.count)
      print("content reports:",self.contentReports.count)
      print("comment reports:",self.commentReports.count)
      print()
      print("count:",self.count)
      print("unchecked:",self.uncheckedCount)
    }
    terminal.add(function: "reports unchecked") {
      let unchecked = Array(self.unchecked.values)
      for report in unchecked {
        print("\(report.id) \(report) (from: \(report.from.first!.userName))")
      }
      print("count:",self.uncheckedCount)
    }
    terminal.add(advanced: "reports decline") { cmd in
      let id = try cmd.int()
      if let report = self.reports[id] {
        print("declined \(report)")
        self.decline(id: id, by: .server)
      } else {
        print("report not found")
      }
    }
    terminal.add(function: "reports decline all unchecked") {
      let unchecked = Array(self.unchecked.values)
      for report in unchecked {
        self.decline(id: report.id, by: .server)
      }
      print("declined \(unchecked.count) reports")
    }
    terminal.add(advanced: "reports accept") { cmd in
      let id = try cmd.int()
      if let report = self.reports[id] {
        print("accepted \(report)")
        self.accept(id: id, by: .server)
      } else {
        print("report not found")
      }
    }
  }
}

