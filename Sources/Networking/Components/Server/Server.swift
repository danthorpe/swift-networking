import Foundation
import HTTPTypes
import os.log

extension NetworkingComponent {

  /// Mutate every request by transforming the property at the keypath.
  /// - Parameters:
  ///   - keypath: `WritableKeyPath` to a property of ``HTTPRequestData``
  ///   - transform: a closure which receives the property denoted by
  ///   the keypath, and should return a new property value.
  ///   - log: a closure which can be used to log info, receiving an
  ///   optional Logger if it's configured.
  /// - Returns: some ``NetworkingComponent``
  public func server<Value: Sendable>(
    mutate keyPath: WritableKeyPath<HTTPRequestData, Value>,
    with transform: @escaping @Sendable (Value) -> Value,
    log: @escaping @Sendable (Logger?, HTTPRequestData) -> Void
  ) -> some NetworkingComponent {
    server { request in
      @NetworkEnvironment(\.logger) var logger
      request[keyPath: keyPath] = transform(request[keyPath: keyPath])
      log(logger, request)
    }
  }

  /// Mutate every request via the block.
  ///
  /// This is very much a building block, it is used for all
  /// other `server*` APIs.
  ///
  /// - Parameter mutateRequest: a closure which receives the ``HTTPRequestData`` to mutate
  /// - Returns: some ``NetworkingComponent``
  public func server(
    mutateRequest: @escaping @Sendable (inout HTTPRequestData) -> Void
  ) -> some NetworkingComponent {
    modified(MutateRequest(mutate: mutateRequest))
  }
}

struct MutateRequest: NetworkingModifier {
  let mutate: @Sendable (inout HTTPRequestData) -> Void
  func resolve(upstream: some NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    var copy = request
    mutate(&copy)
    return copy
  }

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    upstream.send(request)
  }
}
