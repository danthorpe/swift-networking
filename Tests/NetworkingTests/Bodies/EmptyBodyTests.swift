import Foundation
import XCTest

@testable import Networking

final class EmptyBodyTests: XCTestCase {

  func test__basics() async throws {
    let body = EmptyBody()
    XCTAssertTrue(body.isEmpty)
    let encoded = try body.encode()
    XCTAssertEqual(encoded, Data())
  }
}
