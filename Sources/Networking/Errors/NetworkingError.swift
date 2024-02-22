import Foundation
import Helpers

public protocol NetworkingError: Error {
  var request: HTTPRequestData { get }
  var response: HTTPResponseData? { get }

  var requestDidTimeout: HTTPRequestData? { get }
  var isUnauthorizedResponse: HTTPResponseData? { get }
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

  public var requestDidTimeout: HTTPRequestData? {
    if let response, response.status == .requestTimeout {
      return response.request
    } else if let request = (self as? StackError)?.requestDidTimeout {
      return request
    }
    return nil
  }

  public var isUnauthorizedResponse: HTTPResponseData? {
    if let response = (self as? StackError)?.isUnauthorizedResponse {
      return response
    } else if let response, response.status == .unauthorized {
      return response
    }
    return nil
  }
}
