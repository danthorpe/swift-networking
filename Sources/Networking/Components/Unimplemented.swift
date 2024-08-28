public struct Unimplemented: NetworkingComponent {

  public init() {}

  public func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    ResponseStream { continuation in
      continuation.finish(
        throwing: StackError(request: request, kind: .unimplemented)
      )
    }
  }
}
