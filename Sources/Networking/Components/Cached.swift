import Dependencies
import Foundation

extension NetworkingComponent {
  public func cached(in cache: Cache<AnyHashable, HTTPResponseData>) -> some NetworkingComponent {
    modified(Cached()).networkEnvironment(\.cache) {
      CacheClient<AnyHashable, HTTPResponseData>.liveValue(with: cache)
    }
  }
}

public enum CacheOption: HTTPRequestDataOption {
  public static let defaultOption: Self = .always(60)
  case always(TimeInterval)
  case never
}

extension HTTPRequestData {
  public var cacheOption: CacheOption {
    get { self[option: CacheOption.self] }
    set { self[option: CacheOption.self] = newValue }
  }
}

private struct Cached: NetworkingModifier {
  @NetworkEnvironment(\.cache) var cache
  @NetworkEnvironment(\.logger) var logger

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    guard let cache else {
      fatalError("Network Cache was not set correctly")
    }
    guard case let .always(timeToLive) = request.cacheOption else {
      return upstream.send(request)
    }

    let (stream, continuation) = ResponseStream<HTTPResponseData>.makeStream()
    Task {
      if let cachedValue = cache.value(forKey: request) {
        var copy = cachedValue
        copy.set(request: request)
        copy.cachedMetadata = CachedMetadata(
          originalRequest: cachedValue.request
        )
        logger?.info(
          """
          🎯 <\(cachedValue.request.prettyPrintedIdentifier, privacy: .public)>
          \(request.debugDescription, privacy: .public)
          """
        )
        continuation.yield(.value(copy, BytesReceived(data: cachedValue.data)))
        continuation.finish()
        return
      }

      upstream.send(request)
        .map { partial in
          partial.onValue { response in
            cache.insert(value: response, forKey: request, cost: response.cacheCost, duration: timeToLive)
          }
        }
        .redirect(into: continuation)
    }
    return stream
  }
}

extension HTTPResponseData {
  var cacheCost: Int {
    data.count
  }
}

struct CachedMetadata {
  let originalRequest: HTTPRequestData
}

private enum CachedResponseMetadataKey: HTTPResponseMetadata {
  static let defaultMetadata: CachedMetadata? = nil
}

extension HTTPResponseData {
  var cachedMetadata: CachedMetadata? {
    get { self[metadata: CachedResponseMetadataKey.self] }
    set { self[metadata: CachedResponseMetadataKey.self] = newValue }
  }

  public var isCached: Bool {
    nil != cachedMetadata
  }

  public var isNotCached: Bool {
    false == isCached
  }

  public var cachedOriginalRequest: HTTPRequestData? {
    cachedMetadata?.originalRequest
  }
}
