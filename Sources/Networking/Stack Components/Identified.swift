import Foundation
import ShortID
import Tagged
import URLRouting

public extension URLRequestData {
    typealias ID = Tagged<URLRequestData, String>
}

public struct Identified<Upstream: NetworkStackable>: NetworkStackable {
    let upstream: Upstream

    /// This is deliberately not exposed, to prevent framework
    /// consumers from accidentally breaking it.
    init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func data(_ request: URLRequestData) async throws -> URLResponseData {
        try await RequestMetadata.$id.withValue(.init(rawValue: ShortID().description)) {
            return try await upstream.data(request)
        }
    }
}

extension NetworkStackable {
    func identified() -> Identified<Self> {
        Identified(upstream: self)
    }
}
