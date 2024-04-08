import CustomDump
import Dependencies
import Foundation
import ShortID
import TestSupport
import XCTest

@testable import Networking

final class ErrorTests: NetworkingTestCase {

  override func invokeTest() {
    withTestDependencies {
      $0.shortID = .constant(ShortID())
    } operation: {
      super.invokeTest()
    }
  }

  func test__given_data__conveniences() throws {
    let url = URL(static: "https://example.com/failure")
    let data = "Hello World".data(using: .utf8) ?? Data()
    let networkingError = StubbedNetworkError(
      url: url,
      data: data,
      status: .badGateway
    )
    let error: Error = networkingError
    XCTAssertNoDifference(error.httpRequest, HTTPRequestData(path: "/failure"))
    XCTAssertNoDifference(
      error.httpResponse,
      try HTTPResponseData(
        request: HTTPRequestData(path: "/failure"),
        data: data,
        urlResponse: HTTPURLResponse(
          url: url,
          statusCode: 504,
          httpVersion: "HTTP/1.1",
          headerFields: nil)
      )
    )
    XCTAssertNoDifference(error.httpBodyStringRepresentation, "Hello World")
    XCTAssertNoDifference(networkingError.bodyStringRepresentation, "Hello World")
  }

  func test__given_empty_data__conveniences() throws {
    let url = URL(static: "https://example.com/failure")
    let networkingError = StubbedNetworkError(
      url: url,
      status: .badGateway
    )
    let error: Error = networkingError
    XCTAssertNoDifference(error.httpBodyStringRepresentation, "empty body")
    XCTAssertNoDifference(networkingError.bodyStringRepresentation, "empty body")
  }
}
