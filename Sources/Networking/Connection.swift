import Combine
import Foundation
import URLRouting

public struct Connection<Route> {
    var request: (Route) async throws -> URLResponseData

    public init(
        request: @escaping (Route) async throws -> URLResponseData
    ) {
        self.request = request
    }

    public func data(for route: Route) async throws -> (Data, URLResponse) {
        try await request(route).deconstructed
    }

    public func value<Value: Decodable, Decoder: TopLevelDecoder>(
        for route: Route,
        as type: Value.Type = Value.self,
        decoder: Decoder
    ) async throws -> (value: Value, response: URLResponse)
    where Decoder.Input == Data
    {
        // Get the response
        let (data, response) = try await data(for: route)

        // Perform decoding
        do {
            return (try decoder.decode(type, from: data), response)
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
    static func use<Router: ParserPrinter, NetworkStack: NetworkStackable>(router: Router, with stack: NetworkStack) -> Self
    where Router.Input == URLRequestData, Router.Output == Route
    {
        let modified = stack
            // Assigns an incrementing number to each request
            .numbered()
            // Assigns an identifier to each request
            .identified()
            .guarded()

        return Self.init(
            request: { route in
                let requestData = try router.print(route)
                return try await modified.send(requestData)
            }
        )
    }
}
