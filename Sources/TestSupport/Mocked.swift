import Networking

extension NetworkingComponent {
  public func mocked(
    _ stub: StubbedResponseStream,
    check: @escaping @Sendable (HTTPRequestData) -> Bool
  ) -> some NetworkingComponent {
    modified(Mocked(mock: check, with: stub))
  }

  public func mocked(
    _ request: HTTPRequestData,
    stub: StubbedResponseStream
  ) -> some NetworkingComponent {
    mocked(stub) { $0 ~= request }
  }
}

struct Mocked: NetworkingModifier {
  let mock: @Sendable (HTTPRequestData) -> Bool
  let stub: StubbedResponseStream

  @NetworkEnvironment(\.instrument) var instrument

  init(mock: @escaping @Sendable (HTTPRequestData) -> Bool, with stubbedResponse: StubbedResponseStream) {
    self.mock = mock
    self.stub = stubbedResponse
  }

  func resolve(upstream: some NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    request  // Note: We actually do not want to resolve the request to be mocked
  }

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    guard mock(request) else {
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
    _ block: @escaping @Sendable (NetworkingComponent, HTTPRequestData) -> ResponseStream<
      HTTPResponseData
    >
  ) -> some NetworkingComponent {
    modified(CustomMocked(block: block))
  }
}

struct CustomMocked: NetworkingModifier {
  let block: @Sendable (NetworkingComponent, HTTPRequestData) -> ResponseStream<HTTPResponseData>

  func resolve(upstream: some NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    request  // Note: We actually do not want to resolve the request to be mocked
  }

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    block(upstream, request)
  }
}
