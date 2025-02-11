import CustomDump
import Foundation
import ShortID
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct HTTPResponseDataTests: TestableNetwork {

  @Test func test__failed_result_with_non_networking_error() {
    struct OtherError: Error, Hashable {}
    let result: Result<HTTPResponseData, OtherError> = .failure(OtherError())
    #expect(result.httpRequest == nil)
  }

  @Test func test__failed_result_with_networking_error() {
    var request = withTestDependencies {
      HTTPRequestData()
    }
    request.url = URL(static: "https://example.com/failure")
    let networkingError = StubbedNetworkError(
      request: request
    )
    let result: Result<HTTPResponseData, StubbedNetworkError> = .failure(networkingError)
    #expect(result.request == request)
  }

  @Test func test__result_with_success() throws {
    let data = try #require("Hello World".data(using: .utf8))
    let url = URL(static: "https://example.com/failure")
    var request = withTestDependencies {
      HTTPRequestData()
    }
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
    #expect(Result<HTTPResponseData, Error>.success(response).httpRequest == request)
    #expect(Result<HTTPResponseData, StackError>.success(response).request == request)
  }
}
