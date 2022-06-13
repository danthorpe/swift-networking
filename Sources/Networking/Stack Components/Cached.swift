import Cache
import Combine
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

public typealias NetworkCache = Cache<URLRequestData, URLResponseData>

public struct Cached<Upstream: NetworkStackable>: NetworkStackable {
    private(set) var cache: NetworkCache
    public let upstream: Upstream

    public init(in cache: NetworkCache, upstream: Upstream) {
        self.cache = cache
        self.upstream = upstream
        Task {
            let stream = await cache.events
            for try await event in stream {
                if let event = event as? NetworkCache.Event {
                    switch event {
                    case let .willEvictCachedValues(values, reason: reason):
                        print("🗂 Cache will evict values, reason: \(String(describing: reason)), keys: \(values.keys)")
                    default:
                        break
                    }
                }
            }
        }
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
            await cache.insert(response, forKey: request, cost: UInt64(response.data.count), duration: duration)
        }

        return response
    }
}

public extension NetworkStackable {

    func cached(size: Int = 100, fileName: String) -> Cached<Self> {
        let cache = NetworkCache(limit: UInt(size))
//        guard let cache = Cache<URLRequestData, URLResponseData>(size: size, fileName: fileName) else {
//            fatalError("Unable to create cache file named: \(fileName)")
//        }
        return Cached(in: cache, upstream: self)
    }
}
