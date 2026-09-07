import Foundation
import HTTPTypes
import Testing

@testable import Networking

struct RedactedHeaderFieldsOptionTests {

  @Test func defaultsToTheCredentialCarryingHeaders() {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    #expect(request.redactedHeaderFields == [.authorization, .proxyAuthorization, .cookie, .setCookie])
  }

  @Test func roundTrips() {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    request.redactedHeaderFields = [.authorization]
    #expect(request.redactedHeaderFields == [.authorization])
  }

  @Test func notIncludedInEquality() {
    var a = HTTPRequestData(id: .init("1"), authority: "example.com")
    var b = a
    a.redactedHeaderFields = [.authorization]
    b.redactedHeaderFields = []
    #expect(a ~= b)
  }
}
