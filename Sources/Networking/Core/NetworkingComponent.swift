import Foundation
import Helpers

public protocol NetworkingComponent: Sendable {

  /// Send the networking request and receive a stream of events back.
  /// - Parameter request: ``HTTPRequestData`` to send
  /// - Returns: an `AsyncThrowingStream`, which consists of a series of ``BytesReceived`` values, followed by a final ``HTTPResponseData`` element.
  func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData>

  /// Get the final resolved request before it would be sent.
  ///
  /// This is very useful to query the overall networking stack to see how a request might be overall transformed.
  ///
  /// - Parameter request: ``HTTPRequestData`` to send
  /// - Returns: ``HTTPRequestData`` which will be sent on after the component performs any transformations.
  func resolve(_ request: HTTPRequestData) -> HTTPRequestData
}

// MARK: - Default Implementations

extension NetworkingComponent {

  /// Default implementation returns the request without modificiation
  public func resolve(_ request: HTTPRequestData) -> HTTPRequestData {
    request
  }
}

public typealias ResponseStream<Value> = AsyncThrowingStream<Partial<Value, BytesReceived>, Error>
