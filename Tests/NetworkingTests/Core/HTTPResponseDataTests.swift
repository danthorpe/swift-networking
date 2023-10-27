import CustomDump
import Foundation
import ShortID
import TestSupport
import XCTest

@testable import Networking

final class HTTPResponseDataTests: NetworkingTestCase {
  override func invokeTest() {
    withTestDependencies {
      $0.shortID = .constant(ShortID())
    } operation: {
      super.invokeTest()
    }
  }

  func test__failed_result_with_non_networking_error() {
    struct OtherError: Error, Hashable { }
    let result: Result<HTTPResponseData, OtherError> = .failure(OtherError())
    XCTAssertNil(result.httpRequest)
  }

  func test__failed_result_with_networking_error() {
    let data = "Hello World".data(using: .utf8) ?? Data()
    var request = HTTPRequestData()
    request.url = URL(static: "https://example.com/failure")
    let networkingError = StubbedNetworkError(
      request: request
    )
    let result: Result<HTTPResponseData, StubbedNetworkError> = .failure(networkingError)
    XCTAssertNoDifference(result.request, request)
  }

  func test__result_with_success() throws {
    let data = "Hello World".data(using: .utf8) ?? Data()
    let url = URL(static: "https://example.com/failure")
    var request = HTTPRequestData()
    request.url = url
    let response = try HTTPResponseData(
      request: request,
      data: data,
      urlResponse: HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: "HTTP/1.1",
        headerFields: nil
      )
    )

    XCTAssertNoDifference(Result<HTTPResponseData, Error>.success(response).httpRequest, request)
    XCTAssertNoDifference(Result<HTTPResponseData, StackError>.success(response).request, request)
  }
}
