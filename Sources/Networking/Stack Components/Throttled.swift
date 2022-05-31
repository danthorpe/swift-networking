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

public struct Throttled<Upstream: NetworkStackable>: NetworkStackable, ActiveRequestable {
    let data = ActiveRequestsData()

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

        let task = await submit(request, using: upstream)

        if let logger = Logger.current {
            let count = await data.count
            if count > limit {
                logger.info("⏸ 🧵 \(count) requests")
            }
        }

        while await data.count > limit {
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
