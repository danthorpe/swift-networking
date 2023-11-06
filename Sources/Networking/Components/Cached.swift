import Cache
import Dependencies
import Foundation

extension NetworkingComponent {
  public func cached(in cache: Cache<HTTPRequestData, HTTPResponseData>) -> some NetworkingComponent {
    modified(Cached(cache: cache))
  }
}

public enum CacheOption: HTTPRequestDataOption {
  public static var defaultOption: Self = .always(60)
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
  var cache: Cache<HTTPRequestData, HTTPResponseData>
  @NetworkEnvironment(\.logger) var logger
  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    guard case let .always(timeToLive) = request.cacheOption else {
      return upstream.send(request)
    }

    let (stream, continuation) = ResponseStream<HTTPResponseData>.makeStream()
    Task {
      if let cachedValue = await cache.value(forKey: request) {
        var copy = cachedValue
        copy.set(request: request)
        copy.cachedMetadata = CachedMetadata(
          originalRequest: cachedValue.request
        )
        logger?.debug("🎯 Cached from \(cachedValue.request.prettyPrintedIdentifier)")
        continuation.yield(.value(copy, BytesReceived(data: cachedValue.data)))
        continuation.finish()
        return
      }

      await upstream.send(request)
        .redirect(into: continuation, onElement: { element in
          if !Task.isCancelled, case let .value(response, _) = element {
            await cache.insert(response, forKey: request, cost: response.cacheCost, duration: timeToLive)
          }
        }, onError: nil, onTermination: nil)
    }
    return stream
  }
}

extension HTTPResponseData {
  var cacheCost: UInt64 {
    UInt64(data.count)
  }
}

struct CachedMetadata {
  let originalRequest: HTTPRequestData
}

private enum CachedResponseMetadataKey: HTTPResponseMetadata {
  static var defaultMetadata: CachedMetadata?
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
