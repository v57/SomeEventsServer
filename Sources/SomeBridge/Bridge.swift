//
//  bridge.swift
//  faggot server
//
//  Created by Дмитрий Козлов on 28/01/16.
//  Copyright © 2016 anus. All rights reserved.
//

import SomeData

public var wifiIP = "10.0.1.3"
public var publicIP = "events.lino-dska.ru"
public var port = 1989
public var httpPort = 8081
public var address = addr.pub//custom("10.0.1.27")
public var addresses: [String: String] = ["Main": publicIP, "Macbook": "10.0.1.3", "Localhost": localhost]

#if os(iOS)
  public typealias SInt = Int64
#else
  public typealias SInt = Int
#endif
public typealias ID = SInt
public typealias MessageIndex = Int
public typealias UserAvatarVersion = UInt8
public typealias UserMainVersion = UInt16
public typealias UserProfileVersion = UInt16
public typealias UserPrivateVersion = SInt
public typealias EventPreviewVersion = SInt
public typealias ID2 = vec2<ID>

public extension DataReader {
  func id() throws -> ID {
    return try next()
  }
  func messageIndex() throws -> MessageIndex {
    return try next()
  }
}


public struct AppVersion {
  public static var client: Int = 3
  public static var server: Int = 2
  public static var minimum: Int = 3
  public static var isOutdated: Bool {
    return minimum > client
  }
}

extension PhotoData: DataRepresentable {
  public init(data: DataReader) throws {
    width = try data.next()
    height = try data.next()
    size = try data.next()
    guard width > 0 && height > 0 && size >= 0 else { throw corrupted }
  }
  public func save(data: DataWriter) {
    data.append(width)
    data.append(height)
    data.append(size)
  }
}

extension VideoData: DataRepresentable {
  public init(data: DataReader) throws {
    width = try data.next()
    height = try data.next()
    duration = try data.next()
    size = try data.next()
  }
  public func check() throws {
    guard width > 0 && height > 0 && duration > 0 && size >= 0 else { throw corrupted }
  }
  public func save(data: DataWriter) {
    data.append(width)
    data.append(height)
    data.append(duration)
    data.append(size)
  }
}

