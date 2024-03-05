import Foundation
import Helpers

package struct StackError: Error {
  enum Info {
    case request(HTTPRequestData)
    case response(HTTPResponseData)
  }
  enum Kind {
    case createURLRequestFailed
    case decodingResponse
    case invalidURLResponse(Data, URLResponse?)
    case statusCode
    case timeout
    case unauthorized
    case unknown
  }

  let info: Info
  let kind: Kind
  let error: Error
}

// MARK: - Init

extension StackError {

  init(request: HTTPRequestData, kind: Kind, error: Error = NoUnderlyingError()) {
    self.init(info: .request(request), kind: kind, error: error)
  }

  init(response: HTTPResponseData, kind: Kind, error: Error = NoUnderlyingError()) {
    self.init(info: .response(response), kind: kind, error: error)
  }

  init(_ error: Error, with info: Info) {
    if let stackError = error as? StackError {
      self = stackError
    }
    self.init(info: info, kind: .unknown, error: error)
  }

  struct NoUnderlyingError: Error, Equatable { }
}

// MARK: Conformances

extension StackError.Info: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.request(lhs), .request(rhs)):
      return lhs == rhs
    case let (.response(lhs), .response(rhs)):
      return lhs == rhs
    default:
      return false
    }
  }
}

extension StackError.Kind: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.createURLRequestFailed, .createURLRequestFailed),
      (.decodingResponse, .decodingResponse),
      (.statusCode, .statusCode),
      (.timeout, .timeout),
      (.unauthorized, .unauthorized),
      (.unknown, .unknown):
      return true
    case let (.invalidURLResponse(lhsD, lhsR), .invalidURLResponse(rhsD, rhsR)):
      return lhsD == rhsD && lhsR == rhsR
    default:
      return false
    }
  }
}

extension StackError: Equatable {
  package static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.info == rhs.info && lhs.kind == rhs.kind && _isEqual(lhs.error, rhs.error)
  }
}

// MARK: - Pattern Match

func ~= (lhs: StackError.Kind, rhs: Error) -> Bool {
  guard let stackError = rhs as? StackError else { return false }
  return stackError.kind == lhs
}
