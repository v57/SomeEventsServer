//
//  DataFileURL.swift
//  Some
//
//  Created by Дмитрий Козлов on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//
import SomeFunctions

#if os(iOS)
  extension SomeSettings {
    public static var dataWriterProtection = false
  }
  
  public extension DataWriter {
    func write(to url: FileURL) throws {
      if SomeSettings.dataWriterProtection {
        try data.write(to: url.url, options: .completeFileProtection)
      } else {
        try data.write(to: url)
      }
    }
  }
#else
  public extension DataWriter {
    func write(to url: FileURL) throws {
      try data.write(to: url)
    }
  }
#endif
