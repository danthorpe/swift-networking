import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.authentication))
struct BearerCredentialsTests {
  @Test func test__apply_credentials() {
    let credentials = BearerCredentials(token: "super!$3cret")
    let request = credentials.apply(to: HTTPRequestData(id: "1"))
    #expect(request.headerFields[.authorization] == "Bearer super!$3cret")
  }

  @Test func test__provide_credentials() {
    var request = HTTPRequestData(id: "1")
    request.bearerCredentials = BearerCredentials(token: "super!$3cret")
    #expect(request.bearerCredentials?.token == "super!$3cret")
    #expect(request.authenticationMethod == .bearer)
  }

  @Test func test__automatically_apply_credentials() {
    var original = HTTPRequestData(id: "1")
    original.bearerCredentials = BearerCredentials(token: "super!$3cret")
    let request = original.applyAuthenticationCredentials()
    #expect(request.authenticationMethod == .bearer)
    #expect(request.headerFields[.authorization] == "Bearer super!$3cret")
  }
}
