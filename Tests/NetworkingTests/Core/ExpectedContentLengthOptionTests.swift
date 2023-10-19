import Dependencies
import Foundation
import TestSupport
import XCTest

@testable import Networking

final class ExpectedContentLengthOptionTests: XCTestCase {
  func test__expected_content_length_option() {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    XCTAssertNil(request.expectedContentLength)
    request.expectedContentLength = 100
    XCTAssertEqual(request.expectedContentLength, 100)
  }
}
