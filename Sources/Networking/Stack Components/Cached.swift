import Cache
import Foundation
import os.log
import URLRouting

// MARK: - Cache Option

public enum CacheOption: URLRequestOption {
    public static var defaultValue: Self = .always(duration: 3_600)

    case always(duration: TimeInterval)
    case never
}

private extension URLRequestData {
    var cacheOption: CacheOption {
        self[option: CacheOption.self]
    }
}

// MARK: - Cached Network Stack

public struct Cached<Upstream: NetworkStackable>: NetworkStackable {
    private(set) var cache: Cache<URLRequestData, URLResponseData>
    public let upstream: Upstream

    public init(in cache: Cache<URLRequestData, URLResponseData>, upstream: Upstream) {
        self.cache = cache
        self.upstream = upstream
    }

    public func data(_ request: URLRequestData) async throws -> URLResponseData {

        if case .always = request.cacheOption, let response = await cache.value(forKey: request) {
            if let logger = Logger.current {
                logger.info("🎯 Cached from: \(response.request.description)")
            }
            return response
        }
        
        let response = try await upstream.data(request)

        if case let .always(duration) = request.cacheOption {
            await cache.insert(response, duration: duration, forKey: request)
        }

        return response
    }
}

public extension NetworkStackable {

    func use(cache: Cache<URLRequestData, URLResponseData>) -> Cached<Self> {
        Cached(in: cache, upstream: self)
    }
}
