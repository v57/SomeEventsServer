//
//  Numbers.swift
//  Some
//
//  Created by Дмитрий Козлов on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation


public protocol Primitive: Hashable {
  init()
  init(data: DataReader) throws
  func write(to data: inout Data)
}

enum Types: UInt8 {
  case u64 = 200, u32, u16, u8
}

#if __LP64__
  extension UInt: Primitive {
    public init(data: DataReader) throws {
      let raw: UInt8 = try data.next()
      if let type = Types(rawValue: raw) {
        switch type {
        case .u8:
          let value: UInt8 = try data.convert()
          self.init(value)
        case .u16:
          let value: UInt16 = try data.convert()
          self.init(value)
        case .u32:
          let value: UInt32 = try data.convert()
          self.init(value)
        case .u64:
          let value: UInt64 = try data.convert()
          self.init(value)
        }
      } else if raw < 100 {
        self.init(raw)
      } else {
        throw corrupted
      }
    }
    public func write(to data: inout Data) {
      if self < 100 {
        data.append(UInt8(self))
      } else if self <= 0xff {
        data.append(Types.u8)
        data.append(UInt8(self))
      } else if self <= 0xffff {
        data.append(Types.u16)
        data.append(UInt16(self))
      } else if self <= 0xffffffff {
        data.append(Types.u32)
        data.append(UInt32(self))
      } else {
        data.append(Types.u64)
        data.append(UInt64(self))
      }
    }
  }
  extension Int: Primitive {
    public init(data: DataReader) throws {
      let raw: UInt8 = try data.next()
      if let type = Types(rawValue: raw) {
        switch type {
        case .u8:
          let value: Int8 = try data.convert()
          self.init(value)
        case .u16:
          let value: Int16 = try data.convert()
          self.init(value)
        case .u32:
          let value: Int32 = try data.convert()
          self.init(value)
        case .u64:
          let value: Int64 = try data.convert()
          self.init(value)
        }
      } else if raw < 100 {
        self.init(raw)
      } else if raw < 200 {
        self.init(raw-200)
      } else {
        throw corrupted
      }
    }
    public func write(to data: inout Data) {
      if self >= 0 && self < 100 {
        data.append(UInt8(self))
      } else if self >= -100 && self < 0 {
        data.append(UInt8(self+200))
      } else if self <= 0x7f && self >= -0x7f {
        data.append(Types.u8)
        data.append(Int8(self))
      } else if self <= 0x7fff && self >= -0x7fff {
        data.append(Types.u16)
        data.append(Int16(self))
      } else if self <= 0x7fffffff && self >= -0x7fffffff {
        data.append(Types.u32)
        data.append(Int32(self))
      } else {
        data.append(Types.u64)
        data.append(Int64(self))
      }
    }
  }
#else
  
  extension UInt: Primitive {
    public init(data: DataReader) throws {
      let raw: UInt8 = try data.next()
      if let type = Types(rawValue: raw) {
        switch type {
        case .u8:
          let value: UInt8 = try data.convert()
          self.init(value)
        case .u16:
          let value: UInt16 = try data.convert()
          self.init(value)
        case .u32:
          let value: UInt32 = try data.convert()
          self.init(value)
        default:
          throw corrupted
        }
      } else if raw < 100 {
        self.init(raw)
      } else {
        throw corrupted
      }
    }
    public func write(to data: inout Data) {
      if self < 100 {
        data.append(UInt8(self))
      } else if self <= 0xff {
        data.append(Types.u8)
        data.append(UInt8(self))
      } else if self <= 0xffff {
        data.append(Types.u16)
        data.append(UInt16(self))
      } else {
        data.append(Types.u32)
        data.append(UInt32(self))
      }
    }
  }
  extension Int: Primitive {
    public init(data: DataReader) throws {
      let raw: UInt8 = try data.next()
      if let type = Types(rawValue: raw) {
        switch type {
        case .u8:
          let value: Int8 = try data.convert()
          self.init(value)
        case .u16:
          let value: Int16 = try data.convert()
          self.init(value)
        case .u32:
          let value: Int32 = try data.convert()
          self.init(value)
        default:
          throw corrupted
        }
      } else if raw < 100 {
        self.init(raw)
      } else if raw < 200 {
        self.init(Int(raw)-200)
      } else {
        throw corrupted
      }
    }
    public func write(to data: inout Data) {
      if self >= 0 && self < 100 {
        data.append(UInt8(self))
      } else if self >= -100 && self < 0 {
        data.append(UInt8(self+200))
      } else if self <= 0x7f && self >= -0x7f {
        data.append(Types.u8)
        data.append(Int8(self))
      } else if self <= 0x7fff && self >= -0x7fff {
        data.append(Types.u16)
        data.append(Int16(self))
      } else {
        data.append(Types.u32)
        data.append(Int32(self))
      }
    }
  }
#endif
extension UInt64: Primitive {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: UInt8 = try data.convert()
        self.init(value)
      case .u16:
        let value: UInt16 = try data.convert()
        self.init(value)
      case .u32:
        let value: UInt32 = try data.convert()
        self.init(value)
      case .u64:
        let value: UInt64 = try data.convert()
        self.init(value)
      }
    } else if raw < 100 {
      self.init(raw)
    } else {
      throw corrupted
    }
  }
  public func write(to data: inout Data) {
    let max: UInt64 = 0xffffffff
    if self < 100 {
      data.append(UInt8(self))
    } else if self <= 0xff {
      data.append(Types.u8)
      data.append(UInt8(self))
    } else if self <= 0xffff {
      data.append(Types.u16)
      data.append(UInt16(self))
    } else if self <= max {
      data.append(Types.u32)
      data.append(UInt32(self))
    } else {
      data.append(Types.u64)
      data.append(self)
    }
  }
}
extension UInt32: Primitive {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: UInt8 = try data.convert()
        self.init(value)
      case .u16:
        let value: UInt16 = try data.convert()
        self.init(value)
      case .u32:
        let value: UInt32 = try data.convert()
        self.init(value)
      default:
        throw corrupted
      }
    } else if raw < 100 {
      self.init(raw)
    } else {
      throw corrupted
    }
  }
  public func write(to data: inout Data) {
    if self < 100 {
      data.append(UInt8(self))
    } else if self <= 0xff {
      data.append(Types.u8)
      data.append(UInt8(self))
    } else if self <= 0xffff {
      data.append(Types.u16)
      data.append(UInt16(self))
    } else {
      data.append(Types.u32)
      data.append(self)
    }
  }
}
extension UInt16: Primitive {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  
  public func write(to data: inout Data) {
    data.append(self)
  }
}
extension UInt8: Primitive {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  
  public func write(to data: inout Data) {
    data.append(self)
  }
}

extension Int64: Primitive {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: Int8 = try data.convert()
        self.init(value)
      case .u16:
        let value: Int16 = try data.convert()
        self.init(value)
      case .u32:
        let value: Int32 = try data.convert()
        self.init(value)
      case .u64:
        let value: Int64 = try data.convert()
        self.init(value)
      }
    } else if raw < 100 {
      self.init(raw)
    } else if raw < 200 {
      self.init(Int64(raw)-200)
    } else {
      throw corrupted
    }
  }
  public func write(to data: inout Data) {
    if self >= 0 && self < 100 {
      data.append(UInt8(self))
    } else if self >= -100 && self < 0 && self < 0 {
      data.append(UInt8(self+200))
    } else if self <= 0x7f && self >= -0x7f {
      data.append(Types.u8)
      data.append(Int8(self))
    } else if self <= 0x7fff && self >= -0x7fff {
      data.append(Types.u16)
      data.append(Int16(self))
    } else if self <= 0x7fffffff && self >= -0x7fffffff {
      data.append(Types.u32)
      data.append(Int32(self))
    } else {
      data.append(Types.u64)
      data.append(Int64(self))
    }
  }
}
extension Int32: Primitive {
  public init(data: DataReader) throws {
    let raw: UInt8 = try data.next()
    if let type = Types(rawValue: raw) {
      switch type {
      case .u8:
        let value: Int8 = try data.convert()
        self.init(value)
      case .u16:
        let value: Int16 = try data.convert()
        self.init(value)
      case .u32:
        let value: Int32 = try data.convert()
        self.init(value)
      default: throw corrupted
      }
    } else if raw < 100 {
      self.init(raw)
    } else if raw < 200 {
      self.init(Int32(raw)-200)
    } else {
      throw corrupted
    }
  }
  public func write(to data: inout Data) {
    if self >= 0 && self < 100 {
      data.append(UInt8(self))
    } else if self >= -100 && self < 0 {
      data.append(UInt8(self+200))
    } else if self <= 0x7f && self >= -0x7f {
      data.append(Types.u8)
      data.append(Int8(self))
    } else if self <= 0x7fff && self >= -0x7fff {
      data.append(Types.u16)
      data.append(Int16(self))
    } else {
      data.append(Types.u32)
      data.append(Int32(self))
    }
  }
}
extension Int16: Primitive {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  public func write(to data: inout Data) {
    data.append(self)
  }
}
extension Int8: Primitive {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  public func write(to data: inout Data) {
    data.append(self)
  }
}

extension Float: Primitive {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  public func write(to data: inout Data) {
    data.append(self)
  }
}
extension Double: Primitive {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  public func write(to data: inout Data) {
    data.append(self)
  }
}
extension Bool: Primitive {
  public init(data: DataReader) throws {
    self = try data.convert()
  }
  public func write(to data: inout Data) {
    data.append(self)
  }
}
