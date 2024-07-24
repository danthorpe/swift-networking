import ConcurrencyExtras
import Foundation

extension NetworkingComponent {
  func networkEnvironment<Value: Sendable>(
    _ keyPath: WritableKeyPath<NetworkEnvironmentValues, Value>,
    _ value: @escaping @Sendable () -> Value
  ) -> some NetworkingComponent {
    let _keyPath = UncheckedSendable(keyPath)
    return modified(
      NetworkEnvironmentWritingModifier {
        $0[keyPath: _keyPath.value] = value()
      })
  }
}

private struct NetworkEnvironmentWritingModifier: NetworkingModifier {
  let update: @Sendable (inout NetworkEnvironmentValues) -> Void

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    withNetworkEnvironment(update) {
      upstream.send(request)
    }
  }
}

public protocol NetworkEnvironmentKey {
  associatedtype Value: Sendable = Self
}

@propertyWrapper
public struct NetworkEnvironment<Value>: @unchecked Sendable {
  private let keyPath: KeyPath<NetworkEnvironmentValues, Value>

  public var wrappedValue: Value {
    NetworkEnvironmentValues.current[keyPath: keyPath]
  }

  public init(
    _ keyPath: KeyPath<NetworkEnvironmentValues, Value>
  ) {
    self.keyPath = keyPath
  }
}

public struct NetworkEnvironmentValues: Sendable {
  @TaskLocal public static var current = Self()
  private var storage: [ObjectIdentifier: AnySendable] = [:]

  public subscript<Key: NetworkEnvironmentKey>(
    key: Key.Type
  ) -> Key.Value? where Key.Value: Sendable {
    get {
      guard
        let base = self.storage[ObjectIdentifier(key)]?.base,
        let value = base as? Key.Value
      else {
        return nil
      }
      return value
    }
    set {
      self.storage[ObjectIdentifier(key)] = AnySendable(newValue)
    }
  }
}

@discardableResult
func withNetworkEnvironment<R>(
  _ updateNetworkEnvironmentForOperation: (inout NetworkEnvironmentValues) throws -> Void,
  operation: () throws -> R
) rethrows -> R {
  var environment = NetworkEnvironmentValues.current
  try updateNetworkEnvironmentForOperation(&environment)
  return try NetworkEnvironmentValues.$current.withValue(environment) {
    try operation()
  }
}

struct AnySendable: @unchecked Sendable {
  let base: Any
  @inlinable
  init<Base: Sendable>(_ base: Base) {
    self.base = base
  }
}
