import Dependencies
import Foundation
import Helpers

extension NetworkingComponent {
    public func automaticRetry() -> some NetworkingComponent {
        modified(Retry())
    }
}

struct Retry: NetworkingModifier {
    let data = RetryData()

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        guard request.supportsRetryingRequests else {
            return upstream.send(request)
        }
        return ResponseStream { continuation in
            Task {
                await data
                    .send(upstream: upstream, request: request)
                    .redirect(into: continuation)
            }
        }
    }
}

actor RetryData {
    struct Attempt {
        let request: HTTPRequestData
        let result: Result<HTTPResponseData, Error>
    }
    struct Value {
        let original: HTTPRequestData
        var attempts: [Attempt] = []
    }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock

    private var data: [HTTPRequestData.ID: Value] = [:]

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        return ResponseStream { continuation in
            Task {
                var progress = BytesReceived()
                do {
                    for try await element in upstream.send(request).shared() {
                        progress = element.progress
                        continuation.yield(element)
                    }
                    cleanUp(request: request)
                    continuation.finish()
                } catch {
                    do {
                        // Retry
                        try await retry(
                            request: request,
                            error: error,
                            upstream: upstream,
                            progress: progress
                        )
                        .redirect(into: continuation)
                    } catch {
                        cleanUp(request: request)
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }

    func retry(
        request: HTTPRequestData,
        error: Error,
        upstream: NetworkingComponent,
        progress: BytesReceived
    ) async throws -> ResponseStream<HTTPResponseData> {

        // Check to see if the request has a retry strategy
        guard let strategy = request.retryingStrategy else {
            throw error
        }

        // Figure out the original request id
        let originalRequestID = request.retriedOriginalRequestID ?? request.id

        // Access the retry data
        var data = self.data[originalRequestID] ?? Value(original: request, attempts: [])

        // Append a new Attempt value
        let attempt = Attempt(request: request, result: .failure(error))
        data.attempts.append(attempt)

        // Saving the data back
        self.data[originalRequestID] = data

        // Check to see that we have a delay
        guard let delay = await strategy.retryDelay(
            request: request,
            after: data.attempts.map(\.result),
            date: date(),
            calendar: calendar
        ) else {
            throw error
        }

        // Create a retry-copy of the request
        let copy = request.retry()

        // Print some info to the logger
        NetworkLogger.logger?.info("🤞 Retry \(originalRequestID) after \(String(describing: delay)) seconds.")

        // Return a new response stream
        return ResponseStream { continuation in
            Task {
                // Update the progress to reset it
                continuation.yield(.progress(BytesReceived(received: 0, expected: progress.expected)))
                do {
                    // Delay sending the request
                    try await clock.sleep(for: delay)
                } catch {
                    continuation.finish(throwing: error)
                }
                // Send the request
                await self.send(upstream: upstream, request: copy)
                    .redirect(into: continuation)
            }
        }
    }

    func cleanUp(request: HTTPRequestData) {
        self.data.removeValue(forKey: request.retriedOriginalRequestID ?? request.id)
    }
}

// MARK: Request Option

public enum RetryingStrategyRequestOption: HTTPRequestDataOption {
    public static var defaultOption: RetryingStrategy? = BackoffRetryStrategy
        .constant(delay: .seconds(3), maxAttemptCount: 3)
}

struct RetriedOriginalRequestID: Equatable, HTTPRequestDataOption {
    static var defaultOption: HTTPRequestData.ID?
}

struct RetriedRequestID: Equatable, HTTPRequestDataOption {
    static var defaultOption: HTTPRequestData.ID?
}

extension HTTPRequestData {
    public var retryingStrategy: RetryingStrategy? {
        get { self[option: RetryingStrategyRequestOption.self] }
        set { self[option: RetryingStrategyRequestOption.self] = newValue }
    }

    var supportsRetryingRequests: Bool {
        nil != retryingStrategy
    }

    var retriedOriginalRequestID: HTTPRequestData.ID? {
        get { self[option: RetriedOriginalRequestID.self] }
        set { self[option: RetriedOriginalRequestID.self] = newValue }
    }

    var retriedRequestID: HTTPRequestData.ID? {
        get { self[option: RetriedRequestID.self] }
        set { self[option: RetriedRequestID.self] = newValue }
    }

    func retry() -> HTTPRequestData {
        var retry = HTTPRequestData(
            method: self.method,
            scheme: self.scheme,
            authority: self.authority,
            path: self.path,
            headerFields: self.headerFields,
            body: body
        )
        retry.copy(options: self.options)
        retry.retriedOriginalRequestID = self.retriedOriginalRequestID ?? self.id
        retry.retriedRequestID = self.id
        return retry
    }
}

// MARK: - Retrying Strategy

public protocol RetryingStrategy {
    func retryDelay(
        request: HTTPRequestData,
        after attempts: [Result<HTTPResponseData, Error>],
        date: Date,
        calendar: Calendar
    ) async -> Duration?
}

public struct BackoffRetryStrategy: RetryingStrategy {
    private var block: (HTTPRequestData, [Result<HTTPResponseData, Error>], Date, Calendar) -> Duration?
    public init(block: @escaping (HTTPRequestData, [Result<HTTPResponseData, Error>], Date, Calendar) -> Duration?) {
        self.block = block
    }

    public static func constant(delay: Duration, maxAttemptCount: UInt) -> Self {
        .init { _, attempts, _, _ in
            guard attempts.count < maxAttemptCount else { return nil }
            return delay
        }
    }

    public static func immediate(maxAttemptCount: UInt) -> Self {
        constant(delay: .zero, maxAttemptCount: maxAttemptCount)
    }

    public static func exponential(maxDelay: Duration = .seconds(300), maxAttemptCount: UInt) -> Self {
        let interval: Double = 1
        let rate: Double = 2.0
        return .init { _, attempts, _, _ in
            guard attempts.count < maxAttemptCount else { return nil }
            let delay: Double = (interval * pow(rate, Double(attempts.count))) + .random(in: 0...0.001)
            return min(.seconds(delay), maxDelay)
        }
    }

    public func retryDelay(
        request: HTTPRequestData,
        after attempts: [Result<HTTPResponseData, Error>],
        date: Date,
        calendar: Calendar
    ) async -> Duration? {
        block(request, attempts, date, calendar)
    }
}
