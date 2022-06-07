import Combine
import Foundation
import URLRouting

public struct Connection<Route> {
    public let decoder: JSONDecoder
    var request: (Route) async throws -> URLResponseData

    public init(
        decoder: JSONDecoder,
        request: @escaping (Route) async throws -> URLResponseData
    ) {
        self.decoder = decoder
        self.request = request
    }

    public func data(for route: Route) async throws -> (Data, URLResponse) {
        try await request(route).deconstructed
    }

    public func value<Body: Decodable>(
        for route: Route,
        as type: Body.Type = Body.self,
        decoder specializedDecoder: JSONDecoder? = nil
    ) async throws -> (body: Body, response: URLResponse) {
        // Get the data & response
        let (data, response) = try await data(for: route)

        // Perform decoding
        do {
            return (try (specializedDecoder ?? decoder).decode(type, from: data), response)
        }
        catch {
            throw ConnectionError.decoding(.init(
                bytes: data,
                response: response,
                underlyingError: error
            ))
        }
    }
}

public enum ConnectionError: Error {
    case decoding(DecodingError)
}

public struct DecodingError: Error {
    public let bytes: Data
    public let response: URLResponse
    public let underlyingError: Error
}

public extension Connection {

    init<Router: ParserPrinter, NetworkStack: NetworkStackable>(router: Router, decoder: JSONDecoder = .init(), with stack: NetworkStack)
    where Router.Input == URLRequestData, Router.Output == Route {
        
        let modified = stack
            // Assigns an incrementing number to each request
            .numbered()
            // Assigns an identifier to each request
            .identified()
            // Makes resetting safe
            .guarded()

        self.init(
            decoder: decoder,
            request: { route in
                let requestData = try router.print(route)
                return try await modified.data(requestData)
            }
        )
    }
}
