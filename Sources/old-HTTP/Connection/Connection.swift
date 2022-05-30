import Combine
import Foundation
import URLRouting

/// An HTTP Loader which runs a series of other loaders in turn.
///
/// A general entry point into ``HTTPLoaderBuilder`` syntax, which
/// can be used to build custom HTTP loading pipelines.
public struct Connection<Route> {
    fileprivate let createRequestData: (Route) throws -> URLRequestData
    public let upstream: any HTTPLoadable

    public init<Router, Loader>(_ router: Router, @HTTPLoaderBuilder _ build: () -> Loader)
    where Loader: HTTPLoadable, Router: ParserPrinter, Router.Input == URLRequestData, Router.Output == Route
    {
        createRequestData = { try router.print($0) }
        upstream = GenerateRequestIdentifiers(upstream: build())
    }
}

public extension Connection {

    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func request<Body>(json route: Route, as body: Body.Type = Body.self, decoder: JSONDecoder = .init()) async throws -> Response<Body>
    where Body: Decodable {
        try await request(route, as: body, decoder: decoder)
    }

    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func request<Body, Decoder>(_ route: Route, as body: Body.Type, decoder: Decoder) async throws -> Response<Body>
    where Body: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {

        // Create a request
        let request = try Request<Body>(
            http: HTTPRequest(data: createRequestData(route)),
            decoder: decoder
        )

        // Check for cancellation
        try Task.checkCancellation()

        // TODO: Add Reset Guard Logic here.
        // TODO: Add Cancel on Reset logic to Connection

        // Await the http response
        let response = try await upstream.load(request.http)

        // Check for cancellation
        try Task.checkCancellation()

        // Create a decoded Response
        return try request.decode(response)
    }
}
