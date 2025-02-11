import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.authentication))
struct BasicCredentialsTests {
  @Test func test__apply_credentials() {
    let credentials = BasicCredentials(user: "blob", password: "super!$3cret")
    let request = credentials.apply(to: HTTPRequestData(id: "1"))
    #expect(request.headerFields[.authorization] == "Basic YmxvYjpzdXBlciEkM2NyZXQ=")
  }

  @Test func test__provide_credentials() {
    var request = HTTPRequestData(id: "1")
    request.basicCredentials = BasicCredentials(user: "blob", password: "super!$3cret")
    #expect(request.basicCredentials?.user == "blob")
    #expect(request.basicCredentials?.password == "super!$3cret")
    #expect(request.authenticationMethod == .basic)
  }

  @Test func test__automatically_apply_credentials() {
    var original = HTTPRequestData(id: "1")
    original.basicCredentials = BasicCredentials(user: "blob", password: "super!$3cret")
    let request = original.applyAuthenticationCredentials()
    #expect(request.authenticationMethod == .basic)
    #expect(request.headerFields[.authorization] == "Basic YmxvYjpzdXBlciEkM2NyZXQ=")
  }
}
