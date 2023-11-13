import Foundation
import TestSupport
import XCTest

@testable import Networking

final class DataBodyTests: NetworkingTestCase {

  override func invokeTest() {
    withTestDependencies {
      super.invokeTest()
    }
  }

  func test__empty_data() throws {
    let body = DataBody(
      data: Data(),
      additionalHeaders: [:]
    )
    XCTAssertTrue(body.isEmpty)
    let encoded = try body.encode()
    XCTAssertEqual(encoded, Data())
  }

  func test__additional_headers() throws {
    let body = DataBody(
      data: try XCTUnwrap("secret message".data(using: .utf8)),
      additionalHeaders: [.cookie: "secret cookie"]
    )
    let request = try HTTPRequestData(headerFields: [.accept: "application/json"], body: body)
    XCTAssertEqual(request.headerFields, [
      .accept: "application/json",
      .cookie: "secret cookie"
    ])
  }
}
