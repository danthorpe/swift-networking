
import Foundation

public protocol HTTPRetryStrategy {
    func retryAgainAfterDelay(failedAttemptCount count: UInt, for response: HTTPResponse) -> TimeInterval?
}

public enum RetryOption: HTTPRequestOption {
    public static var defaultValue: HTTPRetryStrategy?
}

public extension HTTPRequest {
    var retryStrategy: HTTPRetryStrategy? {
        get { self[option: RetryOption.self] }
        set { self[option: RetryOption.self] = newValue }
    }
}

public struct ConstantBackoff: HTTPRetryStrategy {
    public let delay: TimeInterval
    public let maximumNumberOfAttempts: Int

    public init(
        delay: TimeInterval,
        maximumNumberOfAttempts: Int
    ) {
        self.delay = delay
        self.maximumNumberOfAttempts = maximumNumberOfAttempts
    }

    public func retryAgainAfterDelay(failedAttemptCount count: UInt, for response: HTTPResponse) -> TimeInterval? {
        guard count <= maximumNumberOfAttempts else { return nil }
        return delay
    }
}

public actor Retry<Upstream: HTTPLoadable>: HTTPLoadable {
    private var active: [HTTPRequest.ID: LoadableTask] = [:]

    public let strategy: HTTPRetryStrategy?
    public let upstream: Upstream

    @inlinable
    public init(strategy: HTTPRetryStrategy?, upstream: Upstream) {
        self.strategy = strategy
        self.upstream = upstream
    }

    @inlinable
    convenience init(strategy: HTTPRetryStrategy?, @HTTPLoaderBuilder _ build: () -> Upstream) {
        self.init(strategy: strategy, upstream: build())
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {

        var response = try await upstream.load(request)

        guard let strategy = request.retryStrategy ?? strategy else {
            return response
        }

        func check(count: UInt, from response: HTTPResponse) -> TimeInterval? {
            return strategy.retryAgainAfterDelay(failedAttemptCount: count, for: response)
        }

        var count: UInt = 1

        while let timeInterval = check(count: count, from: response) {
            count += 1
            try await Task.sleep(seconds: timeInterval)
            try checkCancellation()
            response = try await upstream.load(request)
        }

        return response
    }
}

public extension HTTPLoadable {

    func retry(strategy: HTTPRetryStrategy? = nil) -> Retry<Self> {
        Retry(strategy: strategy, upstream: self)
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds timeInterval: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
    }
}
