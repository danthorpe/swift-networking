import Foundation
import XCTest

@testable import OAuth

final class OAuthSystemPKCETests: XCTestCase {

  // Sample taken from RFC Specification
  // https://datatracker.ietf.org/doc/html/rfc7636#appendix-B

  func test__generate_code_verifier() throws {

    let verifier = _base64URLEncode(octets: [
      116, 24, 223, 180, 151, 153, 224, 37, 79, 250, 96, 125, 216, 173,
      187, 186, 22, 212, 37, 77, 105, 214, 191, 240, 91, 88, 5, 88, 83,
      132, 141, 121,
    ])

    XCTAssertEqual(verifier, "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
  }

  func test__code_challenge() throws {
    try XCTAssertEqual(
      _codeChallengeFor(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"),
      "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
    )
  }

  func test__generate_code_verifiers_are_random_values() throws {
    let verifiers = try (0 ..< 10)
      .map { _ in
        try _generateCodeVerifier()
      }
    XCTAssertEqual(Set(verifiers).sorted(), verifiers.sorted())
  }
}
