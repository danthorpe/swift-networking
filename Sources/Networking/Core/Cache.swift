import ConcurrencyExtras
import Dependencies
import DependenciesMacros
import Foundation

public final class Cache<Key: Hashable & Sendable, Value> {
  private let _cache = NSCache<CacheKey, CacheObject>()
  private let keyAccess = KeyAccess()

  public init() {
    _cache.delegate = keyAccess
  }
}

extension Cache: @unchecked Sendable where Value: Sendable { }

extension Cache {
  public var countLimit: Int {
    get { _cache.countLimit }
    set { _cache.countLimit = newValue }
  }

  public var totalCostLimit: Int {
    get { _cache.totalCostLimit }
    set { _cache.totalCostLimit = newValue }
  }

  func insert(_ value: Value, forKey key: Key, cost: Int = .zero, duration: TimeInterval? = nil) {
    @Dependency(\.date) var now
    let expiresAt = duration.map { now().addingTimeInterval($0) } ?? .distantFuture
    let cacheObject = CacheObject(cost: cost, key: key, value: value, expiresAt: expiresAt)
    insertCacheObject(cacheObject)
  }

  func removeValue(forKey key: Key) {
    removeCacheObject(forCacheKey: CacheKey(key: key))
  }

  func removeAll() {
    _cache.removeAllObjects()
    keyAccess.removeAll()
  }

  func value(forKey key: Key) -> Value? {
    getCacheObject(forCacheKey: CacheKey(key: key))?.value
  }

  subscript(key: Key) -> Value? {
    get { value(forKey: key) }
    set {
      guard let value = newValue else {
        removeValue(forKey: key)
        return
      }
      insert(value, forKey: key)
    }
  }
}

private extension Cache {

  func getCacheObject(forCacheKey cacheKey: CacheKey) -> CacheObject? {
    guard let cacheObject = _cache.object(forKey: cacheKey) else { return nil }
    @Dependency(\.date) var now
    guard now() < cacheObject.expiresAt else {
      removeCacheObject(forCacheKey: cacheKey)
      return nil
    }
    return cacheObject
  }

  func insertCacheObject(_ cacheObject: CacheObject) {
    let key = CacheKey(key: cacheObject.key)
    _cache.setObject(cacheObject, forKey: key, cost: cacheObject.cost)
    keyAccess.insert(cacheObject.key)
  }

  func removeCacheObject(forCacheKey cacheKey: CacheKey) {
    _cache.removeObject(forKey: cacheKey)
    keyAccess.remove(cacheKey.key)
  }
}

extension Cache {
  final class CacheKey: NSObject, Sendable {
    let key: Key
    override var hash: Int { key.hashValue }
    init(key: Key) {
      self.key = key
    }
    override func isEqual(_ object: Any?) -> Bool {
      guard let other = object as? Self else { return false }
      return other.key == key
    }
  }
  final class CacheObject: NSObject {
    let cost: Int
    let key: Key
    let value: Value
    let expiresAt: Date
    init(cost: Int, key: Key, value: Value, expiresAt: Date) {
      self.cost = cost
      self.key = key
      self.value = value
      self.expiresAt = expiresAt
    }
  }
  final class KeyAccess: NSObject, NSCacheDelegate, Sendable {
    let keys = LockIsolated<Set<Key>>([])

    func insert(_ key: Key) {
      _ = keys.withValue { $0.insert(key) }
    }

    func remove(_ key: Key) {
      _ = keys.withValue { $0.remove(key) }
    }

    func removeAll() {
      keys.withValue { $0.removeAll() }
    }

    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject object: Any) {
      guard let cacheValue = object as? CacheObject else { return }
      remove(cacheValue.key)
    }
  }
}

// MARK: - Codable

extension Cache.CacheObject: Codable where Key: Codable, Value: Codable { }

extension Cache: Codable where Key: Codable, Value: Codable {

  public convenience init(from decoder: Decoder) throws {
    self.init()
    let container = try decoder.singleValueContainer()
    let cacheObjects = try container.decode([CacheObject].self)
    for cacheObject in cacheObjects {
      insertCacheObject(cacheObject)
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    let cacheObjects = keyAccess.keys.value
      .map(CacheKey.init)
      .compactMap(getCacheObject(forCacheKey:))
    try container.encode(cacheObjects)
  }

  func saveToDisk(withName name: String, using fileManager: FileManager = .default) throws {
    let folderURLs = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
    guard let fileURL = folderURLs.first?.appending(
      path: name + ".cache",
      directoryHint: .notDirectory
    ) else { return }
    let data = try JSONEncoder().encode(self)
    try data.write(to: fileURL)
  }
}

@DependencyClient
struct CacheClient<Key: Hashable & Sendable, Value: Sendable>: Sendable {
  var insert: @Sendable (_ value: Value, _ forKey: Key, _ cost: Int, _ duration: TimeInterval?) -> Void
  var removeAll: @Sendable () -> Void
  var removeValue: @Sendable (_ forKey: Key) -> Void
  var value: @Sendable (_ forKey: Key) -> Value?
}

extension CacheClient: TestDependencyKey {
  static var testValue: Self { CacheClient() }
}

extension CacheClient {
  static func liveValue(with cache: Cache<Key, Value>) -> Self {
    CacheClient { value, key, cost, duration in
      cache.insert(value, forKey: key, cost: cost, duration: duration)
    } removeAll: {
      cache.removeAll()
    } removeValue: { key in
      cache.removeValue(forKey: key)
    } value: { key in
      cache.value(forKey: key)
    }
  }
}

typealias NetworkCacheClient = CacheClient<HTTPRequestData, HTTPResponseData>

extension NetworkCacheClient: NetworkEnvironmentKey {}

extension NetworkEnvironmentValues {
  var cache: NetworkCacheClient? {
    get { self[NetworkCacheClient.self] }
    set { self[NetworkCacheClient.self] = newValue }
  }
}
