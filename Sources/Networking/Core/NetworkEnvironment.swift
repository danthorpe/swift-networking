import Foundation

extension NetworkingComponent {
    func networkEnvironment<Value: Sendable>(
        _ keyPath: WritableKeyPath<NetworkEnvironmentValues, Value>,
        _ value: @escaping () -> Value
    ) -> some NetworkingComponent {
        modified(NetworkEnvironmentWritingModifier(keyPath: keyPath, value: value))
    }
}

private struct NetworkEnvironmentWritingModifier<
    Value: Sendable
>: NetworkingModifier {
    let keyPath: WritableKeyPath<NetworkEnvironmentValues, Value>
    let value: () -> Value
    init(
        keyPath: WritableKeyPath<NetworkEnvironmentValues, Value>,
        value: @escaping () -> Value
    ) {
        self.keyPath = keyPath
        self.value = value
    }
    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        var values = NetworkEnvironmentValues.environmentValues
        values[keyPath: keyPath] = value()
        return NetworkEnvironmentValues.$environmentValues.withValue(values) {
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
        NetworkEnvironmentValues.environmentValues[keyPath: keyPath]
    }

    public init(
        _ keyPath: KeyPath<NetworkEnvironmentValues, Value>
    ) {
        self.keyPath = keyPath
    }
}


public struct NetworkEnvironmentValues: Sendable {
    @TaskLocal public static var environmentValues = Self()
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

private struct AnySendable: @unchecked Sendable {
    let base: Any
    @inlinable
    init<Base: Sendable>(_ base: Base) {
        self.base = base
    }
}
