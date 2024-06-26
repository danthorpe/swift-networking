import Foundation
import HTTPTypes

extension NetworkingComponent {
  public func checkedStatusCode() -> some NetworkingComponent {
    modified(CheckedStatusCode())
  }
}

struct CheckedStatusCode: NetworkingModifier {
  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    ResponseStream<HTTPResponseData>(
      upstream.send(request)
        .map { try $0.onValue(perform: checkStatusCode) }
    )
  }

  private func checkStatusCode(_ response: HTTPResponseData) throws {
    guard response.status.isFailure else { return }
    // Check for authentication issues
    switch response.status {
    case .unauthorized:
      throw StackError(unauthorized: response)
    default:
      throw StackError(statusCode: response)
    }
  }
}

// MARK: - Error Handling

extension StackError {
  init(unauthorized response: HTTPResponseData) {
    self.init(response: response, kind: .unauthorized)
  }
  init(statusCode response: HTTPResponseData) {
    self.init(response: response, kind: .statusCode)
  }
}
