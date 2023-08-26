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
            throw "TODO: Timeout Error"
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
            throw "TODO: Timeout Error"
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

extension NetworkingComponent {
    public typealias MultipleResponse = [Result<HTTPResponseData, Error>]
    typealias IntermediateStream = AsyncStream<MultipleResponse.Element>
    public typealias MultipleResponseStream = AsyncStream<Partial<MultipleResponse, Double>>

    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func data(
        _ requests: [HTTPRequestData],
        timeout duration: Duration = .seconds(60)
    ) -> MultipleResponseStream {
        data(requests,
             timeout: requests.map(\.requestTimeoutInSeconds).max().map(Duration.seconds) ?? duration,
             using: Dependency(\.continuousClock).wrappedValue
        )
    }

    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func data(
        _ requests: [HTTPRequestData],
        timeout duration: Duration,
        using clock: @escaping @autoclosure () -> any Clock<Duration>
    ) -> MultipleResponseStream {
        data(requests: requests) { request, stream in
            try await stream.first(
                beforeTimeout: min(duration, Duration.seconds(request.requestTimeoutInSeconds)),
                using: clock()
            )
        }
    }

    @available(macOS, deprecated: 13.0)
    @available(iOS, deprecated: 16.0)
    @available(watchOS, deprecated: 9.0)
    @available(tvOS, deprecated: 16.0)
    public func data(
        _ requests: [HTTPRequestData],
        timeout timeInterval: TimeInterval
    ) -> MultipleResponseStream {
        data(requests: requests) { request, stream in
            try await stream.first(
                beforeTimeout: min(timeInterval, TimeInterval(request.requestTimeoutInSeconds))
            )
        }
    }

    private typealias TimeoutStream = @Sendable (HTTPRequestData, IntermediateStream) async throws -> MultipleResponse.Element

    private func data(
        requests: [HTTPRequestData],
        timeout: @escaping TimeoutStream
    ) -> MultipleResponseStream {
        MultipleResponseStream { continuation in
            let progress = ProgressTracker()
            Task {
                let results = await withTaskGroup(
                    of: MultipleResponse.Element.self,
                    returning: MultipleResponse.self
                ) { group in
                    await data(
                        requests: requests,
                        timeout: timeout,
                        progress: progress,
                        group: &group,
                        continuation: continuation
                    )
                }
                continuation.yield(.value(results, 1.0))
                continuation.finish()
            }
        }
    }

    @Sendable private func data(
        requests: [HTTPRequestData],
        timeout: @escaping TimeoutStream,
        progress: ProgressTracker,
        group: inout TaskGroup<MultipleResponse.Element>,
        continuation: MultipleResponseStream.Continuation
    ) async -> MultipleResponse {
        // Iterate through requests
        for request in requests {

            // Set the progress initially
            await progress.set(
                id: request.id,
                bytesReceived: BytesReceived(expected: request.expectedContentLength ?? 0)
            )

            // Function to yield overall progress
            @Sendable func yield(progress bytesReceived: BytesReceived, isFinal: Bool = false) async {
                let bytesReceived = bytesReceived.withExpectedContentLength(from: request)
                // Update the progress
                await progress.set(
                    id: request.id,
                    bytesReceived: bytesReceived
                )
                // Yield overall progress
                let fractionCompleted = await progress.fractionCompleted()
                continuation.yield(.progress(fractionCompleted))
            }

            // Add a task to the group
            group.addTask {
                do {
                    // Co-operative cancellation
                    try Task.checkCancellation()
                    // Process the stream
                    return try await timeout(request, send(request)
                        .compactMap { partial in
                            // Co-operative cancellation
                            try Task.checkCancellation()
                            switch partial {
                            case let .progress(bytesReceived):
                                // Update the progress for this request
                                await yield(progress: bytesReceived)
                                return nil

                            case let .value(response, bytesReceived):
                                // Update the final progress for this request
                                await yield(progress: bytesReceived, isFinal: true)
                                return response
                            }
                        }
                        .map { MultipleResponse.Element.success($0) }
                        .eraseToStream())
                } catch is TimeoutError {
                    return .failure("TODO: Timeout Error")
                } catch {
                    return .failure(error)
                }
            }
        } // end of requests for-in

        return await results(in: group)
    }

    private func results(in group: TaskGroup<MultipleResponse.Element>) async -> MultipleResponse {
        var results: MultipleResponse = []
        for await result in group {
            do {
                results.append(.success(try result.get()))
            } catch {
                results.append(.failure(error))
            }
        }
        return results
    }
}
