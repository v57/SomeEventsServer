
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

public func json(_ object: Any!) -> Data! {
  guard object != nil else { return nil }
  return try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
}

extension String {
  
  public var data: Data {
    return self.data(using: .utf8)!
  }
//  public var uuidData: Data {
//    var data = Data()
//    let password = hashValue
//    for i in 1...16 {
//      let v = UInt64.seed(password, i)
//      let b = UInt8(v & 0xFF)
//      data.append(b)
//    }
//    return data
//  }
//  public var uuid: String {
//    return uuidData.uuidString
//  }
}

extension Data {
  public var json: Any! {
    do {
      return try JSONSerialization.jsonObject(with: self, options: [.mutableContainers, .mutableLeaves])
    } catch {
      return nil
    }
  }
//  public var uuidString: String {
//    var output = ""
//    
//    for (index, byte) in self.enumerated() {
//      let nextCharacter = String(byte, radix: 16, uppercase: true)
//      if nextCharacter.count == 2 {
//        output += nextCharacter
//      } else {
//        output += "0" + nextCharacter
//      }
//      
//      if [3, 5, 7, 9].index(of: index) != nil {
//        output += "-"
//      }
//    }
//    
//    return output
//  }
}






