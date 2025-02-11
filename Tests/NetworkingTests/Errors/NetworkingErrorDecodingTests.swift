import Foundation
import TestSupport
import Testing
import os.log

@testable import Networking

@Suite(.tags(.basics))
struct NetworkingErrorDecodingTests: TestableNetwork {

  @Test func test__basics() throws {
    struct ErrorMessage: Decodable {
      let message: String
    }

    let data = try #require(
      """
      {"message":"There is an error"}
      """
      .data(using: .utf8)
    )

    let error = withTestDependencies {
      StubbedNetworkError(
        url: URL(static: "https://example.com"),
        data: data,
        status: .badGateway
      )
    }

    let errorMessage = try #require(error.decodeResponseBodyIntoJSON(as: ErrorMessage.self))
    #expect(errorMessage.message == "There is an error")
  }
}
