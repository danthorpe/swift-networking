import Dependencies
import Foundation
import Helpers

/// `NetworkingComponent` is a protocol to enable a chain-of-responsibility style networking stack. The
/// stack is comprised of multiple elements, each of which conforms to this protocol.
///
/// It has a single requirement for sending a networking request, and receiving a stream of events back.
public protocol NetworkingComponent {
    func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData>
}

public typealias ResponseStream<Value> = AsyncThrowingStream<Partial<Value, BytesReceived>, Error>

// MARK: - Timed Out single Request/Response Data

extension NetworkingComponent {
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    @discardableResult
    public func data(
        _ request: HTTPRequestData,
        timeout duration: Duration,
        using clock: @autoclosure () -> any Clock<Duration>
    ) async throws -> HTTPResponseData {
        do {
            try Task.checkCancellation()
            return try await send(request)
                .compactMap(\.value)
                .first(beforeTimeout: duration, using: clock())
        } catch is TimeoutError {
            throw StackError.timeout(request)
        }
    }

    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    @discardableResult
    public func data(_ request: HTTPRequestData, timeout duration: Duration) async throws -> HTTPResponseData {
        try await data(request, timeout: duration, using: Dependency(\.continuousClock).wrappedValue)
    }

    @available(macOS, deprecated: 13.0)
    @available(iOS, deprecated: 16.0)
    @available(watchOS, deprecated: 9.0)
    @available(tvOS, deprecated: 16.0)
    @discardableResult
    public func data(_ request: HTTPRequestData, timeout timeInterval: TimeInterval) async throws -> HTTPResponseData {
        do {
            try Task.checkCancellation()
            return try await send(request)
                .compactMap(\.value)
                .first(beforeTimeout: timeInterval)
        } catch is TimeoutError {
            throw StackError.timeout(request)
        }
    }

    @discardableResult
    public func data(_ request: HTTPRequestData, timeout seconds: Int64) async throws -> HTTPResponseData {
        if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            return try await data(request, timeout: Duration(secondsComponent: seconds, attosecondsComponent: 0))
        } else {
            return try await data(request, timeout: TimeInterval(seconds))
        }
    }

    @discardableResult
    public func data(_ request: HTTPRequestData) async throws -> HTTPResponseData {
        try await data(request, timeout: request.requestTimeoutInSeconds)
    }
}
