//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public struct Apply<Upstream: HTTPLoadable>: HTTPLoadable {

    public let upstream: Upstream

    public init<Loader: HTTPLoadable>(environment: Environment.Server, @HTTPLoaderBuilder _ build: () -> Loader) where Upstream == RequestModifier<Loader> {
        self.upstream = RequestModifier(
            modifiy: { request in

                var copy = request

                let environment = request.server ?? Environment.server ?? environment

                if copy.host?.isEmpty ?? true {
                    copy.host = environment.host
                }

                // TODO: What about path prefix

                // We add the prefix defined in the environment alongside
                // the host for all API calls (eg. "/api" for "/api/people)
                // then we add the custom path for that particular request
                // ("/people") safely, making sure "/" is present
//                let prefix = copy.path.hasPrefix("/") ? "" : "/"
//                copy.path = environment.pathPrefix + prefix + copy.path

                // TODO: What about default headers?

                // Merge the query items from the environment
                // (specific request headers have priority)
//                copy.headers.merge(environment.headers) { (current, _) in current }

                return copy

            }, upstream: build())
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
        try await upstream.load(request)
    }
}

public extension HTTPLoadable {

    func apply(environment: Environment.Server) -> Apply<RequestModifier<Self>> {
        Apply(environment: environment) { self }
    }
}
