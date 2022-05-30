import Foundation
import os.log
import URLRouting

public actor Cache<Key: Hashable, Value> {

    let now: () -> Date
    let duration: TimeInterval
    private let storage = NSCache<CacheKey, CachedValue>()

    public init(now: @escaping () -> Date = Date.init, duration: TimeInterval = 12 * 3600) {
        self.now = now
        self.duration = duration
    }

    subscript(key: Key) -> Value? {
        get { value(forKey: key) }
        set {
            guard let newValue = newValue else {
                removeValue(forKey: key)
                return
            }
            insert(newValue, forKey: key)
        }
    }

    func value(forKey key: Key) -> Value? {
        guard let cached = storage.object(forKey: CacheKey(key)) else {
            return nil
        }
        guard now() < cached.expirationDate else {
            removeValue(forKey: key)
            return nil
        }
        return cached.value
    }

    func insert(_ value: Value, forKey key: Key) {
        let date = now().addingTimeInterval(duration)
        storage.setObject(CachedValue(value, expires: date), forKey: CacheKey(key))
    }

    func removeValue(forKey key: Key) {
        storage.removeObject(forKey: CacheKey(key))
    }
}

private extension Cache {
    final class CacheKey: NSObject {
        let key: Key

        override var hash: Int {
            key.hashValue
        }

        init(_ key: Key) {
            self.key = key
        }

        override func isEqual(_ other: Any?) -> Bool {
            guard let value = other as? CacheKey else {
                return false
            }
            return value.key == key
        }
    }

    final class CachedValue {
        let value: Value
        let expirationDate: Date

        init(_ value: Value, expires: Date) {
            self.value = value
            self.expirationDate = expires
        }
    }
}

public enum CacheOption: URLRequestOption {
    public static var defaultValue: Self = .always
    case always, never
}

private extension URLRequestData {
    var cacheOption: CacheOption {
        self[option: CacheOption.self]
    }
}

public struct CachedResponse {
    let data: Data
    let response: URLResponse
}

public struct Cached<Upstream: HTTPLoadable>: HTTPLoadable {

    private(set) var cache: Cache<URLRequestData, CachedResponse>
    public let upstream: Upstream

    public init(in cache: Cache<URLRequestData, CachedResponse>, upstream: Upstream) {
        self.cache = cache
        self.upstream = upstream
    }

    public func load(_ request: URLRequestData) async throws -> (Data, URLResponse) {
        // Define the cache key
        let cacheKey = request

        // Check the cache
        if case .always = request.cacheOption, let cachedResponse = await cache.value(forKey: cacheKey) {
            if let logger = Logger.current {
                logger.info("📦 Cache hit for \(request.path)")
            }
            return (cachedResponse.data, cachedResponse.response)
        }

        // Make the request
        let (data, response) = try await upstream.load(request)

        // Store it in the cache
        if case .always = request.cacheOption {
            await cache.insert(.init(data: data, response: response), forKey: cacheKey)
        }

        return (data, response)
    }
}

public extension HTTPLoadable {

    func cached(now: @escaping () -> Date = Date.init, duration: TimeInterval = 12 * 3600) -> Cached<Self> {
        cached(in: .init(now: now, duration: duration))
    }

    func cached(in cache: Cache<URLRequestData, CachedResponse>) -> Cached<Self> {
        Cached(in: cache, upstream: self)
    }
}
