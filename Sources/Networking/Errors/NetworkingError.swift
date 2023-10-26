import Foundation
import Helpers

public protocol NetworkingError: Error {
  var request: HTTPRequestData { get }
  var response: HTTPResponseData? { get }
}

// MARK: - Conveniences

extension NetworkingError {

  public var bodyStringRepresentation: String {
    guard let response else {
      return "no response"
    }
    guard response.data.isNotEmpty else {
      return "empty body"
    }
    return String(decoding: response.data, as: UTF8.self)
  }

  public var isTimeoutError: Bool {
    if let status = response?.status, status == .requestTimeout {
      return true
    }
    switch self {
    case let stackError as StackError:
      if case .timeout = stackError {
        return true
      }
      return false
    default:
      return false
    }
  }
}
