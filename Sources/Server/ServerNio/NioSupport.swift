//
//  NioSupport.swift
//  CNIOAtomics
//
//  Created by Dmitry on 10/03/2019.
//

import Foundation
import SomeData

public extension DataWriter {
  public func spam() {
    replace(at: 0, with: Data(UInt32(count)))
  }
}
open class NetFile: ProgressProtocol {
  public enum ConnectionType {
    case download, upload
  }
  public var total: Int64 = 0
  public var completed: Int64 = 0
  public var isPaused: Bool = false
  public var isCancelled: Bool = false
  public var isCompleted: Bool { return total != 0 && total == completed }
  public var location: FileURL
  public var tempLocation: FileURL
  
  public init(at url: FileURL) {
    location = url
    tempLocation = url.temp
  }
  
  public func prepare(for type: ConnectionType) {
    if type == .upload {
      total = location.fileSize
      if completed >= total {
        completed = 0
      }
    } else {
      completed = tempLocation.fileSize
      if completed >= total {
        completed = 0
      }
    }
  }
}

public func spammer() -> DataWriter {
  let writer = DataWriter()
  writer.data.append(UInt32(0))
  return writer
}

public enum NetFileError: Error {
  case cantOpen, wrongSize
}

public enum TCPError: Error {
  case disconnected // close, send
}

public enum SendError: Error {
  case notSended
}

public enum ListenError: Error {
  case listenFail
}

public enum ConnectError: Error {
  case queryServerFail, connectionClosed, timeout, unknown
}

public enum ConnectionSide {
  case client, server
}
