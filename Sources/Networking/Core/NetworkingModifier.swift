import Dependencies
import Foundation
import Helpers

public protocol NetworkingModifier {
  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  >
}

extension NetworkingComponent {
  public func modified(_ modifier: some NetworkingModifier) -> some NetworkingComponent {
    Modified(upstream: self, modifier: modifier)
  }
}

private struct Modified<Upstream: NetworkingComponent, Modifier: NetworkingModifier>:
  NetworkingComponent {
  let upstream: Upstream
  let modifier: Modifier
  init(upstream: Upstream, modifier: Modifier) {
    self.upstream = upstream
    self.modifier = modifier
  }
  func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    modifier.send(upstream: upstream, request: request)
  }
}
