import Foundation

extension StackError: NetworkingError {
  package var request: HTTPRequestData {
    switch info {
    case let .request(request):
      return request
    case let .response(response):
      return response.request
    }
  }

  package var response: HTTPResponseData? {
    switch info {
    case .request:
      return nil
    case let .response(response):
      return response
    }
  }

  package var isNotConnectedToInternet: Bool {
    guard case .unknown = kind, let error = error as? URLError else {
      return false
    }
    return error.isNotConnectedToInternet
  }

  package var requestDidTimeout: HTTPRequestData? {
    guard case .timeout = kind, case let .request(request) = info else {
      return nil
    }
    return request
  }

  package var isUnauthorizedResponse: HTTPResponseData? {
    if case .unauthorized = kind, case let .response(response) = info {
      return response
    } else if let response, response.status == .unauthorized {
      return response
    }
    return nil
  }
}
