//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public final class TransportLoader: HTTPLoadable {

    private let transport: Transport

    public init(_ transport: Transport) {
        self.transport = transport
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPLoadableResponse {
        do {
            let urlRequest = try createURLRequest(request: request)
            let (data, response) = try await transport.send(request: urlRequest)
            let httpResponse = try createHTTPResponse(request: request, data: data, response: response)
            return .end(httpResponse)
        } catch {
            throw createHTTPError(request: request, error: error)
        }
    }
}

internal extension TransportLoader {

    func createURLRequest(request: HTTPRequest) throws -> URLRequest {
        guard let url = request.url else {
            throw HTTPError(.invalidRequest(.url), request: request)
        }

        // Build a URL Request
        var urlRequest = URLRequest(url: url)

        // Set the method
        urlRequest.httpMethod = request.method.name

        // Add custom headers
        for (header, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: header)
        }

        if false == request.body.isEmpty {

            // Add additional headers for the body
            for (header, value) in request.body.additionalHeaders {
                urlRequest.addValue(value, forHTTPHeaderField: header)
            }

            // Encode the body
            do {
                urlRequest.httpBody = try request.body.encode()
            }
            catch {
                throw HTTPError(.invalidRequest(.body), request: request, underlyingError: error)
            }
        }

        return urlRequest
    }

    func createHTTPError(request: HTTPRequest, response: HTTPResponse? = nil, error: Error) -> HTTPError {
        // Check to see if we already have an HTTPError
        if let httpError = error as? HTTPError {
            return httpError
        }

        // Check for a URLError
        else if let urlError = error as? URLError {
            let code: HTTPError.Code
            switch urlError.code {
            case .badURL:
                code = .invalidRequest(.url)
            default:
                code = .unknown
            }

            return HTTPError(code, request: request, response: response, underlyingError: urlError)
        }

        // Unknown kind of error
        else {
            return HTTPError(.unknown, request: request, response: response, underlyingError: error)
        }
    }

    func createHTTPResult(request: HTTPRequest, data: Data?, response: URLResponse?, error: Error?) -> HTTPResult {

        // Build an HTTP Response
        var httpResponse: HTTPResponse?

        if let response = response as? HTTPURLResponse {
            httpResponse = HTTPResponse(request: request, response: response, body: data)
        }

        // Check for errors
        if let error = error {
            let httpError = createHTTPError(request: request, response: httpResponse, error: error)
            return .failure(httpError)
        }

        // Check for an http response
        guard let httpResponse = httpResponse else {
            // Neither an http response, nor an error
            let httpError = HTTPError(.invalidResponse, request: request, response: nil, underlyingError: nil)
            return .failure(httpError)
        }

        return .success(httpResponse)
    }

    func createHTTPResponse(request: HTTPRequest, data: Data, response: URLResponse) throws -> HTTPResponse {
        switch createHTTPResult(request: request, data: data, response: response, error: nil) {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}
