import Networking

extension NetworkingComponent {

  public func mocked(
    _ stub: StubbedResponseStream,
    check: @escaping @Sendable (HTTPRequestData) -> Bool
  ) -> some NetworkingComponent {
    mocked { check($0) ? stub : nil }
  }

  public func mocked(
    _ request: HTTPRequestData,
    stub: StubbedResponseStream
  ) -> some NetworkingComponent {
    mocked { $0 ~= request ? stub : nil }
  }

  public func mocked(
    _ stub: @escaping @Sendable (HTTPRequestData) -> StubbedResponseStream?
  ) -> some NetworkingComponent {
    modified(Mocked(mock: stub))
  }
}

struct Mocked: NetworkingModifier {
  let mock: @Sendable (HTTPRequestData) -> StubbedResponseStream?

  @NetworkEnvironment(\.instrument) var instrument

  init(mock: @escaping @Sendable (HTTPRequestData) -> StubbedResponseStream?) {
    self.mock = mock
  }

  func resolve(upstream: some NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    request  // Note: We actually do not want to resolve the request to be mocked
  }

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    guard let stub = mock(request) else {
      return upstream.send(request)
    }
    return ResponseStream { continuation in
      Task {
        await instrument?.measureElapsedTime("Mocked")
        stub(request).redirect(into: continuation)
      }
    }
  }
}

extension NetworkingComponent {
  public func mocked(
    _ block: @escaping @Sendable (NetworkingComponent, HTTPRequestData) async -> ResponseStream<
      HTTPResponseData
    >
  ) -> some NetworkingComponent {
    modified(CustomMocked(block: block))
  }
}

struct CustomMocked: NetworkingModifier {
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
