import Foundation
import Helpers
import HTTPTypes
@testable import Networking

public struct StubbedNetworkError: Error {
  internal let error: any NetworkingError

  public init(_ error: some NetworkingError) {
    self.error = error
  }

  public init(request: HTTPRequestData, data: Data = Data(), response: HTTPURLResponse) {
    guard let httpResponse = response.httpResponse else {
      fatalError("Unable to create HTTPResponse from \(response)")
    }

    self.init(
      StackError(
        statusCode: HTTPResponseData(
          request: request,
          data: data,
          httpUrlResponse: response,
          httpResponse: httpResponse
        )
      )
    )
  }

  public init(request: HTTPRequestData, data: Data = Data(), status: HTTPResponse.Status = .badGateway) {
    guard let httpUrlResponse = HTTPURLResponse(
      url: request.url ?? URL(static: "example.com"),
      statusCode: status.code,
      httpVersion: "HTTP/1.1",
      headerFields: nil
    ) else {
      fatalError("Unable to create HTTPURLResponse from \(status)")
    }
    self.init(request: request, data: data, response: httpUrlResponse)
  }

  public init(
    url: URL = URL(static: "example.com"),
    data: Data = Data(),
    status: HTTPResponse.Status = .badGateway
  ) {
    var request = HTTPRequestData()
    request.url = url
    self.init(request: request, data: data, status: status)
  }
}

extension StubbedNetworkError: Equatable {
  public static func == (lhs: StubbedNetworkError, rhs: StubbedNetworkError) -> Bool {
    _isEqual(lhs.error, rhs.error)
  }
}

extension StubbedNetworkError: NetworkingError {
  public var request: Networking.HTTPRequestData {
    error.request
  }

  public var response: Networking.HTTPResponseData? {
    error.response
  }
}
