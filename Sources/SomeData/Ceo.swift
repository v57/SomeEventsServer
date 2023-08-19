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

import SomeFunctions

extension SomeSettings {
  public static var debugCeo = true
}

public protocol Saveable: class {
  var autosave: Bool { get }
  var version: Int { get set }
  func save(data: DataWriter) throws
  func load(data: DataReader) throws
}
public extension Saveable {
  public var autosave: Bool { return true }
  public var version: Int {
    get { return 0 }
    set { }
  }
}

public protocol CustomSaveable: class {
  func save()
  func load() throws
}

public protocol CustomPath: Saveable {
  var fileName: String { get }
}

extension CustomPath {
  public func save(ceo: SomeCeo) throws {
    let data = ceo.dataWriter
    data.append(hash: self)
    ceo.presave(manager: self, data: data)
    try self.save(data: data)
    let url = ceo.url(for: fileName)
    try ceo.save(data: data, to: url)
  }
}

extension Saveable {
  public func reload(by: Saveable) {}
}

private func print(_ items: Any...) {
  guard SomeSettings.debugCeo else { return }
  let output = items.map { "\($0)" }.joined(separator: " ")
  Swift.print("ceo:",output)
}

open class SomeCeo {
  public static var `default`: ()->SomeCeo = { SomeCeo() }
  
  public var path = "some.db"
  var url: FileURL {
    return url(for: path)
  }
  
  public private(set) var managers = [Manager]()
  var versions = [String: Int]()
  public var isLoaded = false
  public var isPaused = false
  public var isLoginned = false
  var saveableManagers: Int = 0
  
  var dataWriter: DataWriter {
    let data = DataWriter()
    setup(data: data)
    return data
  }
  var dataReader: DataWriter {
    let data = DataWriter()
    setup(data: data)
    return data
  }
  open func setup(data: DataWriter) {
    
  }
  open func setup(data: DataReader) {
    
  }
  
//  public var removeDbOnLogout: Bool { return true }
//  public var secure: Bool { return true }
//  public var password: UInt64 { return 0xc178c12a4f03e978 }
//  public var autosave: Bool { return true }
//  public var autoload: Bool { return true }
  
  public init() {
    
  }
  open func preload(manager: Saveable, data: DataReader) throws {
    try manager.version = data.next()
  }
  open func presave(manager: Saveable, data: DataWriter) {
    if let version = versions[className(manager)] {
      data.append(version)
    } else {
      data.append(manager.version)
    }
  }
  open func url(for path: String) -> FileURL {
    return path.documentsURL
  }
  
  open func append(_ manager: Manager) {
    managers.append(manager)
    if manager is Saveable && !(manager is CustomPath) {
      saveableManagers += 1
    }
  }
  
  open func encrypt(data: DataWriter) {
    
  }
  open func decrypt(data: DataReader) {
    
  }
  
  open func start() {
    guard managers.count > 0 else { return }
    print("starting \(managers.count) managers")
    
    #if os(iOS)
    createNotifications()
    #endif
    
    
    let saveable = managers.compactMap { $0 as? Saveable }
    saveable.forEach { versions[className($0)] = $0.version }
    managers.forEach { $0.start() }
  }
  
  open func login() {
    guard !isLoginned else { return }
    isLoginned = true
    managers.forEach { $0.login() }
  }
  open func logout() {
    guard isLoginned else { return }
    isLoginned = false
    managers.forEach { $0.logout() }
  }
  open func memoryWarning() {
    managers.forEach { $0.memoryWarning() }
  }
  
  open func pause() {
    
  }
  open func resume() {
    
  }
  open func close() {
    
  }
  open func loadFailed(manager: Manager, error: Error) {
    Swift.print("ceo error: cannot load \(className(manager)). \(error)")
  }
  open func saveFailed(manager: Manager, error: Error) {
    Swift.print("ceo error: cannot save \(className(manager)). \(error)")
  }
}

extension SomeCeo {
  public func load() {
    var mdata = [Int64: DataReader]()
    open(url: url) { data in
      do {
        let count = try data.int()
        for _ in 0..<count {
          let data: DataReader = try data.next()
          setup(data: data)
          let hash: Int64 = try data.next()
          mdata[hash] = data
        }
      } catch {
        print("ceo error: \(path) corrupted")
      }
    }
    for manager in managers {
      do {
        if let customDB = manager as? CustomPath {
          let url = self.url(for: customDB.fileName)
          try open(url: url) { data in
            setup(data: data)
            try data.hash(manager)
            try preload(manager: customDB, data: data)
            try customDB.load(data: data)
          }
        } else if let saveable = manager as? Saveable {
          let name = className(manager)
          let hash = Int64(name.hashValue)
          if let data = mdata[hash] {
            try preload(manager: saveable, data: data)
            try saveable.load(data: data)
          }
        } else if let customSaveable = manager as? CustomSaveable {
          try customSaveable.load()
        }
      } catch {
        loadFailed(manager: manager, error: error)
      }
    }
  }
  
  public func save() {
    let start = Time.abs
    
    let data = DataWriter()
    data.append(saveableManagers)
    for manager in managers {
//      let type: String
//      if manager is CustomSaveable {
//        type = "CustomSaveable"
//      } else if manager is CustomDBPath {
//        type = "CustomDBPath"
//      } else if manager is Saveable {
//        type = "Saveable"
//      } else {
//        type = "Not saveable"
//      }
//      print("ceo: saving \(className(manager)) \(type)")
      do {
        if let manager = manager as? CustomSaveable {
          manager.save()
        } else if let manager = manager as? CustomPath {
          try manager.save(ceo: self)
        } else if let manager = manager as? Saveable {
          let managerData = dataWriter
          managerData.append(hash: manager)
          presave(manager: manager, data: managerData)
          try manager.save(data: managerData)
          data.append(managerData)
        }
      } catch {
        saveFailed(manager: manager, error: error)
      }
    }
    if saveableManagers > 0 {
      try? save(data: data, to: url)
    }
    print("ceo saved for \(Time.abs - start) seconds")
  }
}

#if os(iOS)
private extension SomeCeo {
  func createNotifications() {
    #if os(iOS)
    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(_pause), name: NSNotification.Name("UIApplicationDidEnterBackgroundNotification"), object: nil)
    center.addObserver(self, selector: #selector(_resume), name: NSNotification.Name("UIApplicationDidBecomeActiveNotification"), object: nil)
    center.addObserver(self, selector: #selector(_close), name: NSNotification.Name("UIApplicationWillTerminateNotification"), object: nil)
    #endif
  }
  
  @objc func _pause() {
    guard !isPaused else { return }
    isPaused = true
    managers.forEach { $0.pause() }
    pause()
  }
  
  @objc func _resume() {
    guard isPaused else { return }
    isPaused = false
    managers.forEach { $0.resume() }
    resume()
  }
  
  @objc func _close() {
    managers.forEach { $0.close() }
    close()
  }
}
#endif
private extension SomeCeo {
  
  func open(url: FileURL, success: (DataReader)throws->()) rethrows {
    guard let data = DataReader(url: url) else { return }
    guard data.count > 0 else { return }
    decrypt(data: data)
    try success(data)
  }
  func save(data: DataWriter, to url: FileURL) throws {
    if data.isEmpty {
      url.delete()
    } else {
      encrypt(data: data)
      try data.write(to: url)
    }
  }
}

private extension DataWriter {
  func append(hash: Any) {
    let name = className(hash)
    let hash = Int64(name.hashValue)
    print("saving manager \(name) \(hash)")
    append(hash)
  }
}

private extension DataReader {
  func hash(_ value: Any) throws {
    let name = className(value)
    let hash = Int64(name.hashValue)
    let dataHash: Int64 = try next()
//    guard hash == dataHash else { throw corrupted }
  }
}
