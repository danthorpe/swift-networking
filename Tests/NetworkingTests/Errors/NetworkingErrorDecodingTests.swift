import Foundation
import TestSupport
import XCTest
import os.log

@testable import Networking

final class NetworkingErrorDecodingTests: NetworkingTestCase {
  override func invokeTest() {
    withTestDependencies {
      super.invokeTest()
    }
  }

  func test__basics() throws {
    struct ErrorMessage: Decodable {
      let message: String
    }

    let data = try XCTUnwrap(
      """
      {"message":"There is an error"}
      """
      .data(using: .utf8))
    let error = StubbedNetworkError(
      url: URL(static: "https://example.com"),
      data: data,
      status: .badGateway
    )

    let errorMessage = try XCTUnwrap(error.decodeResponseBodyIntoJSON(as: ErrorMessage.self))
    XCTAssertEqual(errorMessage.message, "There is an error")
  }
}
