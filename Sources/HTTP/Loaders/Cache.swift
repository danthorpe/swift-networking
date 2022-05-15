import Foundation

actor Cache<Key: Hashable, Value> {

    let now: () -> Date
    let duration: TimeInterval
    private let storage = NSCache<CacheKey, CachedValue>()

    init(now: @escaping () -> Date = Date.init, duration: TimeInterval = 12 * 3600) {
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

public struct Cached<Upstream: HTTPLoadable>: HTTPLoadable {

    private(set) var cache: Cache<HTTPRequest, HTTPResponse>
    public let upstream: Upstream

    init(cache: Cache<HTTPRequest, HTTPResponse>, upstream: Upstream) {
        self.cache = cache
        self.upstream = upstream
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
        let cacheKey = request
        if let response = await cache.value(forKey: cacheKey) {
            return response
        }
        let response = try await upstream.load(request)
        await cache.insert(response, forKey: cacheKey)
        return response
    }
}
