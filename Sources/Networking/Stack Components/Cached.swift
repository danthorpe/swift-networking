import Foundation
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
    public let upstream: Upstream

    public init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func send(_ request: URLRequestData) async throws -> URLResponseData {
        try await upstream.send(request)
    }
}

public extension NetworkStackable {

    func use(cache: Void) -> Cached<Self> {
        Cached(upstream: self)
    }
}

// MARK: - Cache

