import Dependencies
import Foundation
import Helpers

/// Chain networking components by implementing `NetworkingModifier`
///
/// Provide a public interface via an extension on `NetworkingComponent` which calls
/// through to ``NetworkingComponent/modified(_:)``.
public protocol NetworkingModifier: Sendable {

  /// Perform modifications to the input request
  func resolve(upstream: some NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData

  /// Perform some modification, before sending the request onto the upstread component, and
  /// doing any post-processing to the resultant stream
  /// - Parameters:
  ///   - upstream: the `NetworkingComponent` to propagate the request to.
  ///   - request: the input ``HTTPRequestData`` request
  /// - Returns: a ``ResponseStream<HTTPResponseData>``
  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData>
}

extension NetworkingComponent {
  /// Modify the upstream networking component using a networking modifier.
  /// - Parameter modifier: some ``NetworkingModifier`` value
  /// - Returns: some `NetworkingComponent`
  public func modified(_ modifier: some NetworkingModifier) -> some NetworkingComponent {
    Modified(upstream: self, modifier: modifier)
  }
}

extension NetworkingModifier {
  public func resolve(upstream: some NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    upstream.resolve(request)
  }

  public func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    upstream.send(request)
  }
}

private struct Modified<Upstream: NetworkingComponent, Modifier: NetworkingModifier> {
  let upstream: Upstream
  let modifier: Modifier
}

extension Modified: NetworkingComponent {

  func resolve(_ request: HTTPRequestData) -> HTTPRequestData {
    modifier.resolve(upstream: upstream, request: request)
  }

  func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    modifier.send(upstream: upstream, request: resolve(request))
  }
}
