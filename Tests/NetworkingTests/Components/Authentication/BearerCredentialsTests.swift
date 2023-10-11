import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import XCTest

@testable import Networking

final class BearerCredentialsTests: XCTestCase {
  func test__apply_credentials() {
    let credentials = BearerCredentials(token: "super!$3cret")
    let request = credentials.apply(to: HTTPRequestData(id: "1"))
    XCTAssertEqual(request.headerFields[.authorization], "Bearer super!$3cret")
  }

  func test__provide_credentials() {
    var request = HTTPRequestData(id: "1")
    request.bearerCredentials = BearerCredentials(token: "super!$3cret")
    XCTAssertEqual(request.bearerCredentials?.token, "super!$3cret")
  }
}
