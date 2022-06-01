import Calendaring
import Foundation
import os.log
import URLRouting

public protocol RetryStrategy {
    func retryDelay(for result: Result<URLResponseData, Error>, date: Date, calendar: Calendar, count: UInt) -> TimeInterval?
}

public struct Backoff {

    public static func immediate(maxAttemptCount: UInt) -> Backoff {
        .constant(delay: 0, maxAttemptCount: maxAttemptCount)
    }

    public static func constant(delay: TimeInterval, maxAttemptCount: UInt) -> Backoff {
        .init { _, _, _, count in
            guard count < maxAttemptCount else { return nil }
            return 0
        }
    }

    public static func exponential(maxDelay: TimeInterval = 300, maxAttemptCount: UInt) -> Backoff {
    let interval: TimeInterval = 1.0
    let rate: Double = 2.0
    return self.init { _, _, _, count in
        guard count < maxAttemptCount else { return nil }
        let delay = TimeInterval(interval * pow(rate, Double(count)))
        return min(delay + .random(in: 0...0.001), maxDelay) + .random(in: 0...0.001)
    }
}

    private var backoff: (Result<URLResponseData,Error>, Date, Calendar, UInt) -> TimeInterval?
}

extension Backoff: RetryStrategy {
    public func retryDelay(for result: Result<URLResponseData, Error>, date: Date, calendar: Calendar, count: UInt) -> TimeInterval? {
        backoff(result, date, calendar, count)
    }
}

public enum RetryStrategyOption: URLRequestOption {
    public static var defaultValue: RetryStrategyOption? { .backoff(.constant(delay: 1, maxAttemptCount: 2)) }

    case backoff(Backoff)
    case custom(RetryStrategy)
}

extension RetryStrategyOption: RetryStrategy {
    public func retryDelay(for result: Result<URLResponseData, Error>, date: Date, calendar: Calendar, count: UInt) -> TimeInterval? {
        switch self {
        case let .backoff(strategy):
            return strategy.retryDelay(for: result, date: date, calendar: calendar, count: count)
        case let .custom(strategy):
            return strategy.retryDelay(for: result, date: date, calendar: calendar, count: count)
        }
    }
}

public extension URLRequestData {
    var retryStrategyOption: RetryStrategyOption? {
        get { self[option: RetryStrategyOption.self] }
        set { self[option: RetryStrategyOption.self] = newValue }
    }
}

actor RetryRequestsData {
    struct Value: Equatable {
        let original: URLRequestData
        let attempts: Int
    }

    private var data: [URLRequestData: Value] = [:]

    func count(for request: URLRequestData) -> Int? {
        data[request]?.attempts
    }

    func add(_ request: URLRequestData) {
        let existing = data[request]
        let original = existing?.original ?? request
        let count: Int = (existing?.attempts ?? 0)
        data[request] = Value(original: original, attempts: count + 1)
    }
}

public struct Retry<Upstream: NetworkStackable>: NetworkStackable {
    let data = RetryRequestsData()
    public let upstream: Upstream

    public init(upstream: Upstream) {
        self.upstream = upstream
    }

    func submit(_ request: URLRequestData) async -> Task<URLResponseData, Error> {
        await data.add(request)
        return Task {
            try await upstream.send(request)
        }
    }

    public func send(_ request: URLRequestData) async throws -> URLResponseData {
        let original = await submit(request)
        return try await retry(request: request, result: original.result)
    }
}

extension Retry {

    func checkResultNeedsRetrying(_ result: Result<URLResponseData, Error>) -> Bool {
        switch result {
        case let .success(response) where response.status.success:
            return false
        default:
            return true
        }
    }

    func retry(request: URLRequestData, result: Result<URLResponseData, Error>) async throws -> URLResponseData {
        // Check to see if we need to do any kind of retry
        guard let strategy = request.retryStrategyOption, checkResultNeedsRetrying(result) else {
            return try result.get()
        }

        // Get the number of attempts so far
        let count = await data.count(for: request) ?? 0

        // Check the strategy to see if there is a delay
        guard let delay = strategy.retryDelay(for: result, date: DateProvider.now(), calendar: CalendarProvider.active, count: UInt(count)), delay >= 0 else {
            return try result.get()
        }

        if let logger = Logger.current {
            logger.info("⏸ ⏱ Will retry in \(delay) seconds")
        }

        // Sleep until needed
        try await Task.sleep(seconds: delay)

        // Try again
        return try await send(request)
    }
}

public extension NetworkStackable {

    func retry() -> Retry<Self> {
        Retry(upstream: self)
    }
}
