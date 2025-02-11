import Foundation
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct EmptyBodyTests {

  @Test func basics() async throws {
    let body = EmptyBody()
    #expect(body.isEmpty)
    let encoded = try body.encode()
    #expect(encoded == Data())
  }
}
