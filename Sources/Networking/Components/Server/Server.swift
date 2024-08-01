import Foundation
import HTTPTypes
import Helpers
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
      let oldValue = request[keyPath: keyPath]
      let newValue = transform(oldValue)
      request[keyPath: keyPath] = newValue
      if !_isEqual(oldValue, newValue) {
        log(logger, request)
      }
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

// MARK: - Option to opt out of Server based mutations

/// A `HTTPRequestDataOption` which is used to determine whether "server mutations"
/// will impact a specific `HTTPRequestData`.
///
/// Server mutations are networking modifiers added to the stack by using
/// the `.server()` APIs. Their purpose is to set properties of every request
/// which is sent, such as the server authority.
///
/// However, in some cases, it is useful to be able to bypass all of these
/// modifications, and send the request exactly as specified. To do this,
/// set the option to `.disabled`.
public enum ServerMutationsOption: HTTPRequestDataOption {
  public static let defaultOption: Self = .enabled
  case enabled
  case disabled
}

extension HTTPRequestData {
  public var serverMutations: ServerMutationsOption {
    get { self[option: ServerMutationsOption.self] }
    set { self[option: ServerMutationsOption.self] = newValue }
  }
}

private struct MutateRequest: NetworkingModifier {
  let mutate: @Sendable (inout HTTPRequestData) -> Void

  func resolve(upstream: some NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    guard case .enabled = request.serverMutations else { return request }
    var copy = request
    mutate(&copy)
    return copy
  }

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    upstream.send(request)
  }
}
