import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import XCTest

@testable import Networking

final class BasicCredentialsTests: XCTestCase {
  func test__apply_credentials() {
    let credentials = BasicCredentials(user: "blob", password: "super!$3cret")
    let request = credentials.apply(to: HTTPRequestData(id: "1"))
    XCTAssertEqual(request.headerFields[.authorization], "Basic YmxvYjpzdXBlciEkM2NyZXQ=")
  }
  
  func test__provide_credentials() {
    var request = HTTPRequestData(id: "1")
    request.basicCredentials = BasicCredentials(user: "blob", password: "super!$3cret")
    XCTAssertEqual(request.basicCredentials?.user, "blob")
    XCTAssertEqual(request.basicCredentials?.password, "super!$3cret")
  }
}
