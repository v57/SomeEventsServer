
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

//public var root = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first! + "/" // root folder (~/Documents/)
//public var temp = NSTemporaryDirectory()
//public var cache = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .allDomainsMask, true).first! + "/"
//
////func cachePath() -> String {
////  return cache
////}
////func tempPath
//
//public var debugShell = false
//
//public func mkdir(_ path: String, _ documents: Bool = true) { // create directory
//  do {
//    try FileManager.default.createDirectory(atPath: documents ? root+path : path, withIntermediateDirectories: true, attributes: nil)
//    if debugShell {
//      print("mkdir \(path)")
//    }
//  } catch {
//    
//  }
//}
//
////public func printFileSystem() {
////  print()
////  print("documents:")
////  for file in ls("") {
////    print(file)
////  }
////  print()
////  print("lsr:")
////  for file in ls_R("") {
////    print(file)
////  }
////  print()
////  print("content:")
////  let url = root.path
////  let path = url.path
////  print(path)
////  let list = url.content.map { $0.path }
////  for file in list {
////    print(file)
////  }
////  print()
////}
//
//public func echo(_ path: String, _ data: Data!) {
//  guard data != nil else { return }
//  if debugShell {
//    if _e(path) {
//      print("echo \(path)")
//    } else {
//      print("touch \(path)")
//      print("echo \(path)")
//    }
//  }
//  do {
//    try data.write(to: path.rootURL)
//  } catch {
//    
//  }
//}
//
//public func mv(_ path1: String, _ path2: String) { // move
//  if debugShell {
//    print("mv \(path1) \(path2)")
//  }
//  if _e(path2) {
//    rm(path2)
//  }
//
//  do {
//    try FileManager.default.moveItem(atPath: root+path1, toPath: root+path2)
//  } catch {
//    
//  }
//}
//public func mv(_ url: URL, _ path: String) {
//  do {
//    try FileManager.default.moveItem(at: url, to: URL(fileURLWithPath: root+path))
//  } catch {}
//}
//public func cp(_ path1: String, _ path2: String) { // copy
//  if debugShell {
//    print("cp \(path1) \(path2)")
//  }
//  do {
//    try FileManager.default.copyItem(atPath: root+path1, toPath: root+path2)
//  } catch _ {}
//}
//public func touch(_ path: String) {
//  if debugShell {
//    print("touch \(path)")
//  }
//  FileManager.default.createFile(atPath: root+path, contents: nil, attributes: nil)
//}
//
//public func _e(_ path: String) -> Bool {
//  let e = FileManager().fileExists(atPath: root+path)
//  if debugShell {
//    print("-e \(path) \(e)")
//  }
//  return e
//}
//public func cat(_ path: String) -> Data! {
//  if debugShell {
//    print("cat \(path)")
//  }
//  let data = try? Data(contentsOf: URL(fileURLWithPath: root+path))
//  if data == nil {
//    print("cat \(path) empty")
//  }
//  return data
//}
//public func ls(_ path: String) -> [String]! {
//  if debugShell {
//    print("ls")
//  }
//  if let enumerator = FileManager.default.enumerator(atPath: root+path) {
//    var array = [String]()
//    while let element = enumerator.nextObject() as? String {
//      array.append(element)
//    }
//    return array
//  } else {
//    return nil
//  }
//}
//public func ls_R(_ path: String) -> [String]! {
//  do {
//    return try FileManager.default.subpathsOfDirectory(atPath: root+path)
//  } catch {
//    return nil
//  }
//}
//public func rm(_ path: String) {
//  do {
//    try FileManager.default.removeItem(atPath: root+path)
//    if debugShell {
//      print("rm \(path)")
//    }
//  } catch _ {}
//}
//public func du_s(_ path: String) -> UInt64 { // folder size
//  if let a = ls_R(path) {
//    var size: UInt64 = 0
//    for file in a {
//      size += du((path as NSString).appendingPathComponent(file))
//    }
//    return size
//  } else {
//    return 0
//  }
//}
//public func du(_ path: String) -> UInt64 { // file size
//  do {
//    let a = try FileManager.default.attributesOfItem(atPath: root+path)[FileAttributeKey.size]
//    let n = a as? NSNumber
//    let u = n?.uint64Value
//    return u ?? 0
//  } catch {
//    return 0
//  }
//}
//
//
