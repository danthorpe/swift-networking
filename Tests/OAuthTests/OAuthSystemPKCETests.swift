import Foundation
import Testing

@testable import OAuth

@Suite
struct OAuthSystemPKCETests {

  // Sample taken from RFC Specification
  // https://datatracker.ietf.org/doc/html/rfc7636#appendix-B

  @Test func test__generate_code_verifier() throws {

    let verifier = _base64URLEncode(octets: [
      116, 24, 223, 180, 151, 153, 224, 37, 79, 250, 96, 125, 216, 173,
      187, 186, 22, 212, 37, 77, 105, 214, 191, 240, 91, 88, 5, 88, 83,
      132, 141, 121,
    ])

    #expect(verifier == "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
  }

  @Test func test__code_challenge() throws {
    try #expect(
      _codeChallengeFor(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
    )
  }

  @Test func test__generate_code_verifiers_are_random_values() throws {
    let verifiers = try (0 ..< 10)
      .map { _ in
        try _generateCodeVerifier()
      }
    #expect(Set(verifiers).sorted() == verifiers.sorted())
  }
}
