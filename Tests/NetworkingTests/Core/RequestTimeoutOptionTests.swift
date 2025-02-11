import Dependencies
import Foundation
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.basics, .options))
struct RequestTimeoutOptionTests {
  @Test func test__request_timeout_option() {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    #expect(request.requestTimeoutInSeconds == 60)
    request.requestTimeoutInSeconds = 100
    #expect(request.requestTimeoutInSeconds == 100)
  }
}
