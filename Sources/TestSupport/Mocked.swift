import Networking

extension NetworkingComponent {

  /// Mock a given request with a stub
  public func mocked(
    _ request: HTTPRequestData,
    stub: StubbedResponseStream
  ) -> some NetworkingComponent {
    mocked(stub) { $0 ~= request }
  }

  /// Mock the provided stub, after evaluating the request via the check
  public func mocked(
    _ stub: StubbedResponseStream,
    check: @escaping @Sendable (HTTPRequestData) -> Bool
  ) -> some NetworkingComponent {
    mocked { check($0) ? stub : nil }
  }

  /// Evaluate the request, returning a stub to use for mocking, or nil to pass through without mocking
  public func mocked(
    _ mock: @escaping @Sendable (HTTPRequestData) -> StubbedResponseStream?
  ) -> some NetworkingComponent {
    mocked { upstream, request in
      ResponseStream { continuation in
        Task {
          if let stub = mock(request) {
            stub(request).redirect(into: continuation)
          } else {
            upstream.send(request).redirect(into: continuation)
          }
        }
      }
    }
  }

  /// Create a fully custom mock, given the upstream component, and request, returning a response stream.
  public func mocked(
    _ block: @escaping @Sendable (NetworkingComponent, HTTPRequestData) async -> ResponseStream<
      HTTPResponseData
    >
  ) -> some NetworkingComponent {
    modified(CustomMocked(block: block))
  }
}

private struct CustomMocked: NetworkingModifier {
  let block: @Sendable (NetworkingComponent, HTTPRequestData) async -> ResponseStream<HTTPResponseData>

  func resolve(upstream: some NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    request  // Note: We actually do not want to resolve the request to be mocked
  }

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    ResponseStream { continuation in
      Task {
        await block(upstream, request).redirect(into: continuation)
      }
    }
  }
}
