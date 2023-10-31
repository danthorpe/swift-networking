import Networking

extension NetworkingComponent {
  public func mocked(
    _ stub: StubbedResponseStream,
    check: @escaping (HTTPRequestData) -> Bool
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
  let mock: (HTTPRequestData) -> Bool
  let stub: StubbedResponseStream

  @NetworkEnvironment(\.instrument) var instrument

  init(mock: @escaping (HTTPRequestData) -> Bool, with stubbedResponse: StubbedResponseStream) {
    self.mock = mock
    self.stub = stubbedResponse
  }

  func resolve(upstream: NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    request // Note: We actually do not want to resolve the request to be mocked
  }

  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    guard mock(request) else {
      return upstream.send(request)
    }
    return ResponseStream { continuation in
      Task {
        await instrument?.measureElapsedTime("Mocked")
        await stub(request).redirect(into: continuation)
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

  func resolve(upstream: NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    request // Note: We actually do not want to resolve the request to be mocked
  }

  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    block(upstream, request)
  }
}
