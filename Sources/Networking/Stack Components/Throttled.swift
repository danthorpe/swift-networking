import Concurrency
import Foundation
import os.log
import URLRouting

public enum ThrottleOption {
    public static var defaultValue: Self { .always }
    case always, never
}

public struct Throttled<Upstream: NetworkStackable>: NetworkStackable, ActiveRequestable {
    let state = ActiveRequestsState()

    public let limit: Int
    public let upstream: Upstream

    public init(limit: Int, upstream: Upstream) {
        self.limit = limit
        self.upstream = upstream
    }

    public func data(_ request: URLRequestData) async throws -> URLResponseData {
        guard case .always = ThrottleOption.defaultValue else {
            return try await upstream.data(request)
        }

        let task = await submit(request, using: upstream)

        if let logger = Logger.current {
            let count = await state.count
            if count > limit {
                logger.info("⏸ 🧵 \(count) requests")
            }
        }

        while await state.count > limit {
            await Task.yield()
            try Task.checkCancellation()
        }

        return try await task.value
    }
}

public extension NetworkStackable {

    func throttle(max: Int) -> Throttled<Self> {
        Throttled(limit: max, upstream: self)
    }
}
