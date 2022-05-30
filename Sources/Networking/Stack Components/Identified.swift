import Foundation
import ShortID
import Tagged
import URLRouting

public extension URLRequestData {
    typealias ID = Tagged<URLRequestData, String>
}

public struct RequestID: URLRequestOption {
    public static var defaultValue: URLRequestData.ID = "undefined-request-id"
}

extension URLRequestData: Identifiable {
    public internal(set) var id: URLRequestData.ID {
        get { options[option: RequestID.self] }
        set { options[option: RequestID.self] = newValue }
    }
}

public struct Identified<Upstream: NetworkStackable>: NetworkStackable {
    let upstream: Upstream

    /// This is deliberately not exposed, to prevent framework
    /// consumers from accidentally breaking it.
    init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func send(_ request: URLRequestData) async throws -> URLResponseData {
        var copy = request
        copy.id = .init(rawValue: ShortID().description)
        return try await upstream.send(request)
    }
}

extension NetworkStackable {
    func identified() -> Identified<Self> {
        Identified(upstream: self)
    }
}
