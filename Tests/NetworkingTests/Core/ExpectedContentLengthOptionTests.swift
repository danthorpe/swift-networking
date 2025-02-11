import Dependencies
import Foundation
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct ExpectedContentLengthOptionTests {

  @Test func test__expected_content_length_option() {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    #expect(request.expectedContentLength == nil)
    request.expectedContentLength = 100
    #expect(request.expectedContentLength == 100)
  }
}
