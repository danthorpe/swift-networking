import Dependencies
import Foundation
import Helpers

/// Chain networking components by implementing `NetworkingModifier`
///
/// Provide a public interface via an extension on `NetworkingComponent` which calls
/// through to `modified(_ : some NetworkingModifier)`.
public protocol NetworkingModifier {

  /// Perform modifications to the input request
  func resolve(upstream: NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData

  /// Perform some modification, before sending the request onto the upstread component, and
  /// doing any post-processing to the resultant stream
  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData>
}

extension NetworkingModifier {
  public func resolve(upstream: NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    upstream.resolve(request)
  }

  public func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    upstream.send(request)
  }
}

extension NetworkingComponent {
  public func modified(_ modifier: some NetworkingModifier) -> some NetworkingComponent {
    Modified(upstream: self, modifier: modifier)
  }
}

private struct Modified<Upstream: NetworkingComponent, Modifier: NetworkingModifier> {
  let upstream: Upstream
  let modifier: Modifier
  init(upstream: Upstream, modifier: Modifier) {
    self.upstream = upstream
    self.modifier = modifier
  }
}

extension Modified: NetworkingComponent {

  func resolve(_ request: HTTPRequestData) -> HTTPRequestData {
    modifier.resolve(upstream: upstream, request: request)
  }

  func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    modifier.send(upstream: upstream, request: resolve(request))
  }
}
