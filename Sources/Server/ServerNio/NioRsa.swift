//
//  NioRsa.swift
//  SomeFunctions
//
//  Created by Dmitry on 10/03/2019.
//

import Foundation
import CNIOOpenSSL

enum OpenSSLError: Error {
  case invalidKey(Int32)
}
private extension Int32 {
  func check(_ expected: Int) throws {
    guard self == expected else { throw OpenSSLError.invalidKey(self) }
  }
}

public class Bio {
  public var bio: UnsafeMutablePointer<BIO>?
  var data: Data {
    var m: UnsafeRawPointer!
    let count = BIO_ctrl(bio, BIO_CTRL_INFO, 0, &m)
    return Data(bytes: m, count: count)
  }
  public init() {
    self.bio = BIO_new(BIO_s_mem())
  }
  init(_ data: Data) {
    let size = data.count
    let pointer = data.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
      return UnsafeRawPointer(p)
    }
    
    self.bio = BIO_new(BIO_s_mem())
    
    let mem = BUF_MEM_new()
    BUF_MEM_grow(mem, data.count)
    
    if let data = mem?.pointee.data {
      memcpy(data, pointer, size)
    }
    BIO_ctrl(bio, BIO_C_SET_BUF_MEM, Int(BIO_CLOSE), UnsafeMutableRawPointer(mutating: mem))
  }
  deinit {
    if let bio = bio {
      BIO_free(bio)
      self.bio = nil
    }
  }
}

public class Rsa {
  let pkey: UnsafeMutablePointer<EVP_PKEY>?
  public init(publicKey: Data) throws {
    pkey = EVP_PKEY_new()
    let f = Bio(publicKey)
    let rsa = d2i_RSAPublicKey_bio(f.bio, nil)
    do {
      try EVP_PKEY_assign(pkey, EVP_PKEY_RSA, rsa).check(1)
    } catch {
      RSA_free(rsa)
    }
  }
  public init(privateKey: Data) throws {
    pkey = EVP_PKEY_new()
    let f = Bio(privateKey)
    let rsa = d2i_RSAPrivateKey_bio(f.bio, nil)
    do {
      try EVP_PKEY_assign(pkey, EVP_PKEY_RSA, rsa).check(1)
    } catch {
      RSA_free(rsa)
    }
  }
  public init(size bits: Int = 2048) {
    var kp: UnsafeMutablePointer<EVP_PKEY>?
    let ctx = EVP_PKEY_CTX_new_id(EVP_PKEY_RSA, nil)
    EVP_PKEY_keygen_init(ctx)
    EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_RSA, EVP_PKEY_OP_KEYGEN, EVP_PKEY_CTRL_RSA_KEYGEN_BITS, Int32(bits), nil)
    EVP_PKEY_keygen(ctx, &kp)
    pkey = kp
  }
  deinit {
    EVP_PKEY_free(pkey)
  }
  public var publicKey: Data {
    let mem = Bio()
    let rsa = EVP_PKEY_get1_RSA(pkey)
    i2d_RSAPublicKey_bio(mem.bio, rsa)
    return mem.data
  }
  public var privateKey: Data {
    let mem = Bio()
    let rsa = EVP_PKEY_get1_RSA(pkey)
    i2d_RSAPrivateKey_bio(mem.bio, rsa)
    return mem.data
  }
  public func encrypt(_ data: Data) -> Data {
    let rsa = EVP_PKEY_get1_RSA(pkey)
    var out = Data(count: Int(RSA_size(rsa)))
    RSA_public_encrypt(Int32(data.count), data.withUnsafeBytes{$0}, out.withUnsafeMutableBytes{$0}, rsa, RSA_PKCS1_OAEP_PADDING)
    return out
  }
  public func decrypt(_ data: Data) -> Data {
    let rsa = EVP_PKEY_get1_RSA(pkey)
    var out = Data(count: Int(RSA_size(rsa)))
    
    let c = RSA_private_decrypt(Int32(data.count), data.withUnsafeBytes{$0}, out.withUnsafeMutableBytes{$0}, rsa, RSA_PKCS1_OAEP_PADDING)
    out.count = Int(c)
    return out
  }
  public func lock(data: inout Data) {
    data = encrypt(data)
  }
  public func unlock(data: inout Data) throws {
    data = decrypt(data)
  }
}
