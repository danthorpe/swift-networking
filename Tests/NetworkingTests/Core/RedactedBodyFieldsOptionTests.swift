import Foundation
import Testing

@testable import Networking

struct RedactedBodyFieldsOptionTests {
  @Test func defaultsToEmptyAndRoundTrips() {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    #expect(request.redactedBodyFields == [])
    request.redactedBodyFields = ["access_token", "refresh_token"]
    #expect(request.redactedBodyFields == ["access_token", "refresh_token"])
  }

  @Test func notIncludedInEquality() {
    var a = HTTPRequestData(id: .init("1"), authority: "example.com")
    var b = a
    a.redactedBodyFields = ["access_token"]
    b.redactedBodyFields = []
    #expect(a ~= b)  // pattern-match equality ignores non-equality options
  }
}
