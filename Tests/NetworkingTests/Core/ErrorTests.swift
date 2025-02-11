import CustomDump
import Dependencies
import Foundation
import ShortID
import TestSupport
import Testing

@testable import Networking

struct ErrorTests: TestableNetwork {

  @Test func test__given_data__conveniences() throws {
    let url = URL(static: "https://example.com/failure")
    let data = "Hello World".data(using: .utf8) ?? Data()
    try withTestDependencies {
      $0.shortID = .constant(ShortID())
    } operation: {
      let networkingError = StubbedNetworkError(
        url: url,
        data: data,
        status: .badGateway
      )
      let error: Error = networkingError
      #expect(error.httpRequest == HTTPRequestData(path: "/failure"))
      let expectedResponseData = try HTTPResponseData(
        request: HTTPRequestData(path: "/failure"),
        data: data,
        urlResponse: HTTPURLResponse(
          url: url,
          statusCode: 504,
          httpVersion: "HTTP/1.1",
          headerFields: nil
        )
      )
      #expect(error.httpResponse == expectedResponseData)
      #expect(error.httpBodyStringRepresentation == "Hello World")
      #expect(networkingError.bodyStringRepresentation == "Hello World")
    }
  }

  @Test func test__given_empty_data__conveniences() throws {
    let url = URL(static: "https://example.com/failure")
    withTestDependencies {
      let networkingError = StubbedNetworkError(
        url: url,
        status: .badGateway
      )
      let error: Error = networkingError
      #expect(error.httpBodyStringRepresentation == "empty body")
      #expect(networkingError.bodyStringRepresentation == "empty body")
    }
  }
}
