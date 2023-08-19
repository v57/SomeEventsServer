
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

extension MutableCollection where Iterator.Element == UInt8, Index == Int, IndexDistance == Int {
  public mutating func encrypt(password: UInt64, offset: Int = 0) {
    guard count > 0 else { return }
    for i in 0..<count {
      let v = UInt64.seed(password, UInt64(i+offset))
      let b = UInt8(v & 0xFF)
      self[i] = self[i] &+ b
    }
  }
  public mutating func decrypt(password: UInt64, offset: Int = 0) {
    guard count > 0 else { return }
    for i in 0..<count {
      let v = UInt64.seed(password, UInt64(i+offset))
      let b = UInt8(v & 0xFF)
      self[i] = self[i] &- b
    }
  }
}

extension Data {
  public mutating func encrypt(password: UInt64, from: Int) {
//    print("encrypting \(hexString2)\n with \(password), from: \(from)")
    let count = self.count
    withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
      for i in from..<count {
        let v = UInt64.seed(password, UInt64(i))
        let b = UInt8(v & 0xFF)
        bytes[i] = bytes[i] &+ b
      }
    }
  }
  public mutating func decrypt(password: UInt64, from: Int) {
//    print("decrypting \(hexString2)\n with \(password), from: \(from)")
    let count = self.count
    withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
      for i in from..<count {
        let v = UInt64.seed(password, UInt64(i))
        let b = UInt8(v & 0xFF)
        bytes[i] = bytes[i] &- b
      }
    }
  }
  public mutating func encrypt(password: UInt64, offset: Int = 0) {
//    print("encrypting \(hexString2)\n with \(password), offset: \(offset)")
    let count = self.count
    withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
      for i in 0..<count {
        let v = UInt64.seed(password, UInt64(i+offset))
        let b = UInt8(v & 0xFF)
        bytes[i] = bytes[i] &+ b
      }
    }
  }
  public mutating func decrypt(password: UInt64, offset: Int = 0) {
//    print("decrypting \(hexString2)\n with \(password), offset: \(offset)")
    let count = self.count
    withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
      for i in 0..<count {
        let v = UInt64.seed(password, UInt64(i+offset))
        let b = UInt8(v & 0xFF)
        bytes[i] = bytes[i] &- b
      }
    }
  }
}

extension DataReader {
  public func decrypt(password: UInt64, offset: Int) {
    data.decrypt(password: password, offset: offset)
  }
  public func decrypt(password: UInt64) {
    data.decrypt(password: password, from: position)
  }
}

extension DataWriter {
  public func encrypt(password: UInt64, from: Int) {
    data.encrypt(password: password, from: from)
  }
  public func encrypt(password: UInt64, offset: Int = 0) {
    data.encrypt(password: password, offset: offset)
  }
}

