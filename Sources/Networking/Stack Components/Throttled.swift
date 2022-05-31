import Concurrency
import Foundation
import os.log
import URLRouting

public enum ThrottleOption: URLRequestOption {
    public static var defaultValue: Self { .always }
    case always, never
}

extension URLRequestData {
    var throttle: ThrottleOption {
        get { self[option: ThrottleOption.self] }
        set { self[option: ThrottleOption.self] = newValue }
    }
}

private let data = ActiveRequestsData()

public struct Throttled<Upstream: NetworkStackable>: NetworkStackable {
    public let limit: Int
    public let upstream: Upstream

    public init(limit: Int, upstream: Upstream) { 
        self.limit = limit
        self.upstream = upstream
    }

    public func send(_ request: URLRequestData) async throws -> URLResponseData {
        guard case .always = request.throttle else {
            return try await upstream.send(request)
        }

        let task = Task<URLResponseData, Error> {
            let result = try await upstream.send(request)
            await data.removeTask(for: request)
            return result
        }

        let count = await data.add(task, for: request)

        if let logger = Logger.current, count > limit {
            logger.info("⏸ 🧵 \(count) requests")
        }

        while await data.count > limit {
            await Task.yield()
            try Task.checkCancellation()
        }

        return try await task.value
    }
}

public extension NetworkStackable {

    func throttled(max: Int) -> Throttled<Self> {
        Throttled(limit: max, upstream: self)
    }
}
