import Networking
import XCTestDynamicOverlay

public struct TerminalNetworkingComponent: NetworkingComponent {
  public struct TestFailure: Equatable, Error {
    public let request: HTTPRequestData
    public init(request: HTTPRequestData) {
      self.request = request
    }
  }
  let isFailingTerminal: Bool
  public init(
    isFailingTerminal: Bool = true
  ) {
    self.isFailingTerminal = isFailingTerminal
  }
  public func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    let request = resolve(request)
    return ResponseStream { continuation in
      if isFailingTerminal {
        continuation.finish(throwing: TestFailure(request: request))
      } else {
        continuation.finish()
      }
    }
  }
}
