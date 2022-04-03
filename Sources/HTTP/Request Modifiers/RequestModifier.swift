import Foundation

public struct RequestModifier<Upstream: HTTPLoadable>: HTTPLoadable {

    public let modifiy: (HTTPRequest) -> HTTPRequest
    public let upstream: Upstream

    public init(modifiy: @escaping (HTTPRequest) -> HTTPRequest, upstream: Upstream) {
        self.modifiy = modifiy
        self.upstream = upstream
    }

    public init(modifiy: @escaping (HTTPRequest) -> HTTPRequest, @HTTPLoaderBuilder _ build: () -> Upstream) {
        self.init(modifiy: modifiy, upstream: build())
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
        try await upstream.load(modifiy(request))
    }
}
