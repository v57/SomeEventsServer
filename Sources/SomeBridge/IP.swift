//
//  ip.swift
//  Server
//
//  Created by Дмитрий Козлов on 3/24/17.
//
//

import Foundation

public var localhost = "127.0.0.1"

public struct IP {
  public var ip: String
  public var port: Int
  public var string: String { return "\(ip):\(port)" }
  
  #if os(macOS) || os(Linux)
  public init?(string: String) {
  var split = string.components(separatedBy: ".")
  guard split.count == 4 else { return nil }
  guard let a0 = Int(split[0]) else { return nil }
  guard let a1 = Int(split[1]) else { return nil }
  guard let a2 = Int(split[2]) else { return nil }
  let s3 = split[3].components(separatedBy: ":")
  guard s3.count <= 2 else { return nil }
  guard let a3 = Int(s3[0]) else { return nil }
  
  ip = "\(a0).\(a1).\(a2).\(a3)"
  if s3.count == 2 {
  guard let p = Int(s3[1]) else { return nil }
  guard p < Int(Int16.max) else { return nil }
  port = p
  } else {
  port = 1989
  }
  }
  #endif
  
  public init(ip: String, port: Int) {
    self.ip = ip
    self.port = port
  }
  public init() {
    ip = "127.0.0.1"
    port = 80
  }
  public static var `public`: String? {
    guard let url = URL(string: "https://icanhazip.com/") else { return nil }
    let ip = try? String(contentsOf: url)
    return ip
  }
}


#if os(macOS) || os(Linux)
  extension IP {
    @discardableResult
    public mutating func set(string: String) -> Bool {
      var split = string.components(separatedBy: ".")
      guard split.count == 4 else { return false }
      guard let a0 = Int(split[0]) else { return false }
      guard let a1 = Int(split[1]) else { return false }
      guard let a2 = Int(split[2]) else { return false }
      let s3 = split[3].components(separatedBy: ":")
      guard s3.count <= 2 else { return false }
      guard let a3 = Int(s3[0]) else { return false }
      
      ip = "\(a0).\(a1).\(a2).\(a3)"
      if s3.count == 2 {
        guard let p = Int(s3[1]) else { return false }
        guard p < Int(Int16.max) else { return false }
        port = p
      }
      return true
    }
    
    public static var wifi: String? {
      for address in Host.current().addresses {
        guard address.count < 16 else { continue } // skipping ipv6
        guard address != localhost else { return nil }
        return address
      }
      return nil
    }
  }
#endif


public struct addr {
  public static var local: IP { return IP(ip: localhost, port: port) }
  public static var wifi: IP { return IP(ip: wifiIP, port: port) }
  public static var pub: IP {
//    #if os(iOS)
      return IP(ip: publicIP, port: port)
//    #else
//      return IP(ip: wifiIP, port: port)
//    #endif
  }
  public static func custom(_ ip: String) -> IP {
    return IP(ip: ip, port: port)
  }
}
