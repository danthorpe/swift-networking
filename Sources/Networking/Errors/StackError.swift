import Foundation
import Helpers

enum StackError: Error {
  enum ProgrammingError: Equatable, Sendable {
    // TBD
  }

  case createURLRequestFailed(HTTPRequestData)
  case decodeResponse(HTTPResponseData, Error)
  case invalidURLResponse(HTTPRequestData, Data, URLResponse?)
  case statusCode(HTTPResponseData)
  case timeout(HTTPRequestData)
  case unauthorized(HTTPResponseData)
}

extension StackError: NetworkingError {
  var request: HTTPRequestData {
    switch self {
    case .createURLRequestFailed(let request), .invalidURLResponse(let request, _, _),
      .timeout(let request):
      return request
    case .unauthorized(let response), .decodeResponse(let response, _), .statusCode(let response):
      return response.request
    }
  }

  var response: HTTPResponseData? {
    switch self {
    case .createURLRequestFailed, .invalidURLResponse, .timeout:
      return nil
    case .unauthorized(let response), .decodeResponse(let response, _), .statusCode(let response):
      return response
    }
  }
}

extension StackError: Equatable {
  static func == (lhs: StackError, rhs: StackError) -> Bool {
    switch (lhs, rhs) {
    case let (.createURLRequestFailed(lhs), .createURLRequestFailed(rhs)):
      return lhs == rhs
    case let (.decodeResponse(lhs, lhsE), .decodeResponse(rhs, rhsE)):
      return lhs == rhs && _isEqual(lhsE, rhsE)
    case let (.invalidURLResponse(lhs, lhsD, lhsR), .invalidURLResponse(rhs, rhsD, rhsR)):
      return lhs == rhs && _isEqual(lhsD, rhsD) && lhsR == rhsR
    case let (.statusCode(lhs), .statusCode(rhs)):
      return lhs == rhs
    case let (.timeout(lhs), .timeout(rhs)):
      return lhs == rhs
    case let (.unauthorized(lhs), .unauthorized(rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}
