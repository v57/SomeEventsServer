
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

import Foundation

extension Int {
  public func k() -> String {
    if self > 10000000 {
      return "\(self / 1000000)M"
    } else if self > 10000 {
      return "\(self / 1000)K"
    } else {
      return String(self)
    }
  }
}

extension String {
  public static let videoEmojis = "🎞🎬📽🎥📼📹📺".map { String($0) }
  public static let imageEmojis = "🗾🌁🌃🌄🌅🌆🌇🌉🌌🌠🎆🎇🎑🏙".map { String($0) }
  public static let audioEmojis = "🎶🎵🎧🎼🥁🎷🎸🎹".map { String($0) }
  public static let mapEmojis = "🗺📍".map { String($0) }
  
  public static var videoEmoji: String { return videoEmojis.any }
  public static var imageEmoji: String { return imageEmojis.any }
  public static var audioEmoji: String { return audioEmojis.any }
  public static var mapEmoji: String { return mapEmojis.any }
  public static func *= (l: inout String, r: String) {
    l.addLine(r)
  }
//  public subscript (i: Int) -> Character {
//    get {
//      return self[self.characters.index(self.startIndex, offsetBy: i)]
//    }
//    set {
//      let start = characters.index(startIndex, offsetBy: i)
//      let end = characters.index(start, offsetBy: i + 1)
//      self.replaceSubrange(Range(start..<end), with: String(newValue))
//    }
//  }
//
//  public subscript (i: Int) -> String {
//    get {
//      return String(self[i] as Character)
//    }
//    set {
//      let start = characters.index(startIndex, offsetBy: i)
//      let end = characters.index(start, offsetBy: i + 1)
//      self.replaceSubrange(Range(start..<end), with: newValue)
//    }
//  }
  
//  public subscript (r: CountableClosedRange<Int>) -> String {
//    get {
//      let start = characters.index(startIndex, offsetBy: r.lowerBound)
//      let end = characters.index(start, offsetBy: r.upperBound - r.lowerBound + 1)
//      return String(self[Range(start..<end)])
//    }
//    set {
//      let start = characters.index(startIndex, offsetBy: r.lowerBound)
//      let end = characters.index(start, offsetBy: r.upperBound - r.lowerBound + 1)
//      self.replaceSubrange(Range(start..<end), with: newValue)
//    }
//  }
//  public var count: Int {
//    return count
//  }
  public var lines: [String] {
    return components(separatedBy: "\n")
  }
  public var words: [String] {
    return components(separatedBy: " ")
  }
  public var cleaned: String {
    return trimmingCharacters(in: .whitespacesAndNewlines)
  }
  @discardableResult
  public mutating func remove(prefix: String) -> Bool {
    guard hasPrefix(prefix) else { return false }
    self = removeFirst(prefix.count)
    return true
  }
  @discardableResult
  public mutating func remove(suffix: String) -> Bool {
    guard hasSuffix(suffix) else { return false }
    self = removeLast(suffix.count)
    return true
  }
  public func removing(prefix: String) -> String {
    guard hasPrefix(prefix) else { return self }
    return removeFirst(prefix.count)
  }
  public func removeWWW() -> String {
    if self.hasPrefix("www.") {
      return removeFirst(4)
    }
    return self
  }
  public var isEmail: Bool {
    let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
    return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
//    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
//    return emailTest.evaluate(with: self)
  }
  public mutating func addLine(_ line: String) {
    self = isEmpty ? line : "\(self)\n\(line)"
  }
  public mutating func addLine() {
    guard !isEmpty else { return }
    self += "\n"
  }
  public var localized: String {
    return NSLocalizedString(self, comment: "")
  }
  
  
  public func first(_ count: Int) -> String {
    return String(prefix(count))
  }
  public func removeFirst(_ count: Int) -> String {
    return String(suffix(from: index(startIndex, offsetBy: count)))
  }
  public func last(_ count: Int) -> String {
    return String(suffix(count))
  }
  public func removeLast(_ count: Int) -> String {
    return String(prefix(upTo: index(endIndex, offsetBy: -count)))
  }
  
  public static func numberEnding(_ number: Int) -> Int {
    let lastDigit = number % 10
    if number < 20 && number > 9 {
      return 3
    } else {
      if lastDigit == 1 {
        return 1 // секунда
      } else if lastDigit > 1 && lastDigit < 5 {
        return 2 // секунды
      } else {
        return 3 // секунд
      }
    }
  }
  public static func numberEndingAlt(_ number: Int) -> Int {
    let lastDigit = number % 10
    if number < 20 && number > 9 {
      return 3 // 15 лет
    } else {
      if lastDigit == 1 {
        return 1 // 21 год
      } else if lastDigit > 1 && lastDigit < 5 {
        return 2 // 4 года
      } else {
        return 3 // секунд
      }
    }
  }
  
  public static func random(count: Int, set: StringRange) -> String {
    let characters = Array(set.string)
    guard !characters.isEmpty else { return "" }
    var result = ""
    for _ in 0..<count {
      result += String(characters.any)
    }
    return result
  }
}

public struct StringRange: OptionSet {
  public let rawValue: UInt8
  public init(rawValue: UInt8){ self.rawValue = rawValue}
  public static let az = StringRange(rawValue: 1 << 0)
  public static let AZ = StringRange(rawValue: 1 << 1)
  public static let numbers = StringRange(rawValue: 1 << 2)
  public static let symbols = StringRange(rawValue: 1 << 3)
  public var string: String {
    var string = " "
    if contains(.az) {
      string += "abcdefghijklmnopqrstuvwxyz"
    }
    if contains(.AZ) {
      string += "abcdefghijklmnopqrstuvwxyz".uppercased()
    }
    if contains(.numbers) {
      string += "0123456789"
    }
    if contains(.symbols) {
      string += "!@#$%^&*(){}[]<>_+-=.,:;\"'?/|\\"
    }
    return string
  }
}
