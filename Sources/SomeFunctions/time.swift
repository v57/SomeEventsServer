
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import CoreFoundation
import Foundation

public typealias Time = UInt32

extension DateFormatter {
  public static let styled = DateFormatter()
  public static let formatted = DateFormatter()
}

public func measure(_ text: String, _ code: ()throws->()) {
  let start = Time.abs
  do {
    try code()
    let end = Time.abs
    print("\(text) \(end-start) seconds")
  } catch {
    print("\(text) error: \(error)")
  }
}

extension Time {
  public static var now: Time {
    var time:timeval = timeval(tv_sec: 0, tv_usec: 0)
    gettimeofday(&time, nil)
    return Time(time.tv_sec)
  }
  public static var ms: UInt64 {
    return UInt64(CFAbsoluteTimeGetCurrent() * 1000)
  }
  public static var abs: Double {
    return CFAbsoluteTimeGetCurrent()
  }
  public static var timezone: Time {
    return Time(NSTimeZone.local.secondsFromGMT())
  }
  public static let minute: Time = 60
  public static let hour: Time = 3600
  public static let day: Time = 86400
  public static let week: Time = 604800
  public static let month: Time = 2628000
  public static let year: Time = 31536000
  
  public var year: Int {
    return Calendar.current.component(.year, from: date)
  }
  
  public var date: Date {
    return Date(timeIntervalSince1970: TimeInterval(self))
  }
  public func dateFormat(date: DateFormatter.Style = .none, time: DateFormatter.Style = .none) -> String {
    let df = DateFormatter.styled
    df.dateStyle = date
    df.timeStyle = time
    return df.string(from: self.date)
  }
  public func dateFormat(_ format: String) -> String {
    let df = DateFormatter.formatted
    df.dateFormat = format
    return df.string(from: self.date)
  }
  public var timeFormat: String {
    let df = DateFormatter.styled
    df.dateStyle = .none
    df.timeStyle = .short
    return df.string(from: date)
  }
  public var uniFormat: String {
    let now = Time.now
    var result = ""
    var max = Swift.max(now,self)
    max -= Swift.min(now,self)
    if max > 82800 {
      result.append(dateFormat("MMM dd "))
    }
    if now.year != year {
      result.append("2k")
      result.append(dateFormat("YY "))
    }
    if !result.isEmpty {
      result.append(" ")
    }
    result.append(dateFormat(time: .short))
    return result
  }
  public static func ping(_ start: Double) -> Int {
    return Int((Time.abs - start) * 1000)
  }
}

extension Date {
  public var time: Time {
    return Time(timeIntervalSince1970)
  }
}

extension timeval {
  public static var now: timeval {
    var time:timeval = timeval(tv_sec: 0, tv_usec: 0)
    gettimeofday(&time, nil)
    return time
  }
  public var usecFromNow: Int64 {
    var now:timeval = timeval(tv_sec: 0, tv_usec: 0)
    gettimeofday(&now, nil)
    let sec = Int64(now.tv_sec - self.tv_sec)
    let usec = Int64(now.tv_usec - self.tv_usec)
    return sec * 1000000 + usec
  }
  #if os(iOS)
  public var usecs: Int64 {
  return Int64(tv_sec) * 1000000 + Int64(tv_usec)
  }
  #else
  public var usecs: Int {
    return Int(tv_sec) * 1000000 + Int(tv_usec)
  }
  #endif
  public var sec: Int {
    return self.tv_sec
  }
  public var ms: Int64 {
    return Int64(tv_sec) * 1000 + Int64(tv_usec) / 1000
  }
}
