
public struct Sym {
  private let a: UInt64
  private let b: UInt64
  private let c: UInt64
  private let d: UInt64
  public init() {
    a = .random()
    b = .random()
    c = .random()
    d = .random()
  }
  public init(_ a: UInt64, _ b: UInt64, _ c: UInt64, _ d: UInt64) {
    self.a = a
    self.b = b
    self.c = c
    self.d = d
  }
  public init(data: [UInt64]) {
    a = data[0]
    b = data[1]
    c = data[2]
    d = data[3]
  }
  public func seed(_ x: UInt64, _ y: UInt64) -> UInt64 {
    var y = y
    y = (y >> 13) ^ y
    y = (y &* (y &* y &* x &+ a) &+ b) & 0xffffffffffffffff
    let inner = (y &* (y &* y &* c &+ d) &+ b) & 0xffffffffffffffff
    return inner
  }
  public func seed(_ x: Int, _ y: Int) -> UInt64 {
    let x = UInt64(x)
    var y = UInt64(y)
    y = (y >> 13) ^ y
    y = (y &* (y &* y &* x &+ a) &+ b) & 0xffffffffffffffff
    let inner = (y &* (y &* y &* c &+ d) &+ b) & 0xffffffffffffffff
    return inner
  }
}

#if os(iOS) || os(macOS)
import Foundation

public class Keys {
  public var privateKey: Data?
  public var publicKey: Data
  /// default: 2048
  public init(size: Int = 2048) {
    let (pr,pb) = try! CC.RSA.generateKeyPair(size)
    self.privateKey = pr
    self.publicKey = pb
  }
  public init(public publicKey: Data) {
    self.privateKey = nil
    self.publicKey = publicKey
  }
  public init(public publicKey: Data, private privateKey: Data) {
    self.privateKey = privateKey
    self.publicKey = publicKey
  }
  public func lock(data: inout Data) {
    do {
      data = try CC.RSA.encrypt(data, derKey: publicKey, tag: Data(), padding: .oaep, digest: .sha1)
    } catch {}
  }
  public func unlock(data: inout Data) throws {
    guard let privateKey = privateKey else { return }
    do {
      data = try CC.RSA.decrypt(data, derKey: privateKey, tag: Data(), padding: .oaep, digest: .sha1).0
    } catch {
      throw DataError.corrupted
    }
  }
}

private class CC {
  typealias CCCryptorStatus = Int32
  enum CCError: CCCryptorStatus, Error {
    case paramError = -4300
    case bufferTooSmall = -4301
    case memoryFailure = -4302
    case alignmentError = -4303
    case decodeError = -4304
    case unimplemented = -4305
    case overflow = -4306
    case rngFailure = -4307
    
    static var debugLevel = 1
    
    init(_ status: CCCryptorStatus, function: String = #function,
		       file: String = #file, line: Int = #line) {
      self = CCError(rawValue: status)!
      if CCError.debugLevel > 0 {
        print("\(file):\(line): [\(function)] \(self._domain): \(self) (\(self.rawValue))")
      }
    }
  }
  
  typealias CCDigestAlgorithm = UInt32
  enum DigestAlgorithm: CCDigestAlgorithm {
    case none = 0
    case md5 = 3
    case rmd128 = 4, rmd160 = 5, rmd256 = 6, rmd320 = 7
    case sha1 = 8
    case sha224 = 9, sha256 = 10, sha384 = 11, sha512 = 12
  }
  
  private static let dl = dlopen("/usr/lib/system/libcommonCrypto.dylib", RTLD_NOW)
  
  class RSA {
    
    typealias CCAsymmetricPadding = UInt32
    
    enum AsymmetricPadding: CCAsymmetricPadding {
      case pkcs1 = 1001
      case oaep = 1002
    }
    
    static func generateKeyPair(_ keySize: Int = 4096) throws -> (Data, Data) {
      var privateKey: CCRSACryptorRef? = nil
      var publicKey: CCRSACryptorRef? = nil
      let status = CCRSACryptorGeneratePair!(
        keySize,
        65537,
        &publicKey,
        &privateKey)
      
      try check(status: status)
      
      defer {
        CCRSACryptorRelease!(privateKey!)
        CCRSACryptorRelease!(publicKey!)
      }
      
      let privDERKey = try exportToDERKey(privateKey!)
      let pubDERKey = try exportToDERKey(publicKey!)
      
      return (privDERKey, pubDERKey)
    }
    
    static func encrypt(_ data: Data, derKey: Data, tag: Data, padding: AsymmetricPadding,
		                           digest: DigestAlgorithm) throws -> Data {
      let key = try importFromDERKey(derKey)
      defer { CCRSACryptorRelease!(key) }
      
      var bufferSize = getKeySize(key)
      var buffer = Data(count: bufferSize)
      
      let status = buffer.withUnsafeMutableBytes {
        (bufferBytes: UnsafeMutablePointer<UInt8>) -> CCCryptorStatus in
        return CCRSACryptorEncrypt!(
          key,
          padding.rawValue,
          data.rawPointer,
          data.count,
          bufferBytes,
          &bufferSize,
          tag.rawPointer, tag.count,
          digest.rawValue)
      }
      
      try check(status: status)
      
      buffer.count = bufferSize
      
      return buffer
    }
    
    static func check(status: CCCryptorStatus) throws {
      #if os(macOS) || os(iOS)
      guard status == noErr else { throw CCError(status) }
      #endif
    }
    
    static func decrypt(_ data: Data, derKey: Data, tag: Data, padding: AsymmetricPadding,
		                           digest: DigestAlgorithm) throws -> (Data, Int) {
      let key = try importFromDERKey(derKey)
      defer { CCRSACryptorRelease!(key) }
      
      let blockSize = getKeySize(key)
      
      var bufferSize = blockSize
      var buffer = Data(count: bufferSize)
      
      let status: CCCryptorStatus = buffer.withUnsafeMutableBytes { bufferBytes in
        return CCRSACryptorDecrypt!(
          key,
          padding.rawValue,
          data.rawPointer,
          bufferSize,
          bufferBytes,
          &bufferSize,
          tag.rawPointer, tag.count,
          digest.rawValue)
      }
      
      try check(status: status)
      buffer.count = bufferSize
      
      return (buffer, blockSize)
    }
    
    private static func importFromDERKey(_ derKey: Data) throws -> CCRSACryptorRef {
      var key: CCRSACryptorRef? = nil
      let status = CCRSACryptorImport!(
        derKey.rawPointer,
        derKey.count,
        &key)
      try check(status: status)
      
      return key!
    }
    
    private static func exportToDERKey(_ key: CCRSACryptorRef) throws -> Data {
      var derKeyLength = 8192
      var derKey = Data(count: derKeyLength)
      let status = derKey.withUnsafeMutableBytes {
        (derKeyBytes: UnsafeMutablePointer<UInt8>) -> CCCryptorStatus in
        return CCRSACryptorExport!(key, derKeyBytes, &derKeyLength)
      }
      try check(status: status)
      
      derKey.count = derKeyLength
      return derKey
    }
    
    private static func getKeySize(_ key: CCRSACryptorRef) -> Int {
      return Int(CCRSAGetKeySize!(key)/8)
    }
    
    private typealias CCRSACryptorRef = UnsafeRawPointer
    private typealias CCRSAKeyType = UInt32
    private enum KeyType: CCRSAKeyType {
      case publicKey = 0, privateKey
      case blankPublicKey = 97, blankPrivateKey
      case badKey = 99
    }
    
    private typealias CCRSACryptorGeneratePairT = @convention(c) (
      _ keySize: Int,
      _ e: UInt32,
      _ publicKey: UnsafeMutablePointer<CCRSACryptorRef?>,
      _ privateKey: UnsafeMutablePointer<CCRSACryptorRef?>) -> CCCryptorStatus
    private static let CCRSACryptorGeneratePair: CCRSACryptorGeneratePairT? =
      getFunc(CC.dl!, f: "CCRSACryptorGeneratePair")
    
    private typealias CCRSACryptorReleaseT = @convention(c) (CCRSACryptorRef) -> Void
    private static let CCRSACryptorRelease: CCRSACryptorReleaseT? =
      getFunc(dl!, f: "CCRSACryptorRelease")
    
    private typealias CCRSAGetKeySizeT = @convention(c) (CCRSACryptorRef) -> Int32
    private static let CCRSAGetKeySize: CCRSAGetKeySizeT? = getFunc(dl!, f: "CCRSAGetKeySize")
    
    private typealias CCRSACryptorEncryptT = @convention(c) (
      _ publicKey: CCRSACryptorRef,
      _ padding: CCAsymmetricPadding,
      _ plainText: UnsafeRawPointer,
      _ plainTextLen: Int,
      _ cipherText: UnsafeMutableRawPointer,
      _ cipherTextLen: UnsafeMutablePointer<Int>,
      _ tagData: UnsafeRawPointer,
      _ tagDataLen: Int,
      _ digestType: CCDigestAlgorithm) -> CCCryptorStatus
    private static let CCRSACryptorEncrypt: CCRSACryptorEncryptT? =
      getFunc(dl!, f: "CCRSACryptorEncrypt")
    
    private typealias CCRSACryptorDecryptT = @convention (c) (
      _ privateKey: CCRSACryptorRef,
      _ padding: CCAsymmetricPadding,
      _ cipherText: UnsafeRawPointer,
      _ cipherTextLen: Int,
      _ plainText: UnsafeMutableRawPointer,
      _ plainTextLen: UnsafeMutablePointer<Int>,
      _ tagData: UnsafeRawPointer,
      _ tagDataLen: Int,
      _ digestType: CCDigestAlgorithm) -> CCCryptorStatus
    private static let CCRSACryptorDecrypt: CCRSACryptorDecryptT? =
      getFunc(dl!, f: "CCRSACryptorDecrypt")
    
    private typealias CCRSACryptorExportT = @convention(c) (
      _ key: CCRSACryptorRef,
      _ out: UnsafeMutableRawPointer,
      _ outLen: UnsafeMutablePointer<Int>) -> CCCryptorStatus
    private static let CCRSACryptorExport: CCRSACryptorExportT? =
      getFunc(dl!, f: "CCRSACryptorExport")
    
    private typealias CCRSACryptorImportT = @convention(c) (
      _ keyPackage: UnsafeRawPointer,
      _ keyPackageLen: Int,
      _ key: UnsafeMutablePointer<CCRSACryptorRef?>) -> CCCryptorStatus
    private static let CCRSACryptorImport: CCRSACryptorImportT? =
      getFunc(dl!, f: "CCRSACryptorImport")
    
  }
}

private func getFunc<T>(_ from: UnsafeMutableRawPointer, f: String) -> T? {
  let sym = dlsym(from, f)
  guard sym != nil else {
    return nil
  }
  return unsafeBitCast(sym, to: T.self)
}


#endif
