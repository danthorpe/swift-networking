import Foundation
import HTTPTypes
import os.log

extension NetworkingComponent {

  public func server<Value>(
    mutate keypath: WritableKeyPath<HTTPRequestData, Value>,
    with transform: @escaping (Value) -> Value,
    log: @escaping (Logger?, HTTPRequestData) -> Void
  ) -> some NetworkingComponent {
    server { request in
      @NetworkEnvironment(\.logger) var logger
      request[keyPath: keypath] = transform(request[keyPath: keypath])
      log(logger, request)
    }
  }

  public func server(
    _ mutateRequest: @escaping (inout HTTPRequestData) -> Void
  ) -> some NetworkingComponent {
    modified(MutateRequest(mutate: mutateRequest))
  }
}

struct MutateRequest: NetworkingModifier {
  let mutate: (inout HTTPRequestData) -> Void
  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    var copy = request
    mutate(&copy)
    return upstream.send(copy)
  }
}
