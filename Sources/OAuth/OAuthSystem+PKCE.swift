import CryptoKit
import Foundation

extension OAuth {

  static func generateNewState() throws -> String {
    try _base64URLEncode(octets: _octets(count: 12))
  }

  static func generateNewCodeVerifier(length: Int = 43) throws -> String {
    try _generateCodeVerifier()
  }

  static func codeChallengeFor(verifier: String) throws -> String {
    try _codeChallengeFor(verifier: verifier)
  }
}

func _generateCodeVerifier(length: Int = 43) throws -> String {
  assert((43 ... 128).contains(length), "Invalid length \(length). Code Verifier must be between 43 and 128 characters")
  // Resulting string uses an alphabet of 64 letters =? 2^6, meaning each
  // letter will encode to 6 bits. An octet is 8 bits. Therefore we must
  // multiply our desired length by 6/8 for the number of octets required.
  let count: Int = (length * 6) / 8
  let octets = try _octets(count: count)
  return _base64URLEncode(octets: octets)
}

func _codeChallengeFor(verifier: String) throws -> String {
  let challenge =
    verifier  // String
    .data(using: .ascii)  // Decode back to [UInt8] -> Data?
    .map(SHA256.hash)  // Hash -> SHA256.Digest?
    .map(_base64URLEncode(octets:))  // base64URLEncode

  guard let challenge = challenge else {
    throw OAuth.Error.failedToCreateCodeChallengeForVerifier(verifier)
  }
  return challenge
}

func _octets(count: Int) throws -> [UInt8] {
  var octets = [UInt8](repeating: 0, count: count)
  let status = SecRandomCopyBytes(kSecRandomDefault, octets.count, &octets)
  guard status == errSecSuccess else {
    throw OAuth.Error.failedToCreateSecureRandomData
  }
  return octets
}

func _base64URLEncode<S>(
  octets: S
) -> String where S: Sequence, UInt8 == S.Element {
  let data = Data(octets)
  return
    data
    .base64EncodedString()  // Regular base64 encoder
    .replacingOccurrences(of: "=", with: "")  // Remove any trailing '='s
    .replacingOccurrences(of: "+", with: "-")  // 62nd char of encoding
    .replacingOccurrences(of: "/", with: "_")  // 63rd char of encoding
    .trimmingCharacters(in: .whitespaces)
}
