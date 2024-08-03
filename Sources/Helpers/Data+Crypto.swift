import CryptoKit
import Foundation

extension Data {

  static func secureRandomData(length: UInt) -> Data? {
    let count = Int(length)
    var bytes = [Int8](repeating: 0, count: count)
    guard errSecSuccess == SecRandomCopyBytes(kSecRandomDefault, count, &bytes) else {
      return nil
    }
    return Data(bytes: bytes, count: count)
  }
}
