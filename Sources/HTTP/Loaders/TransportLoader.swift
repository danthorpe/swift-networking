//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public struct NetworkTransport {
    var send: (URLRequest, Progress?) async throws -> (Data, URLResponse)

    public init(send: @escaping (URLRequest, Progress?) async throws -> (Data, URLResponse)) {
        self.send = send
    }
}

extension NetworkTransport {

    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    public static func live(session: URLSession = .shared) -> Self {
        .init { (request, progress) in
            #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            if #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) {
                return try await session.data(for: request)
            }
            #endif

            var dataTask: URLSessionDataTask?
            let cancel: () -> Void = { dataTask?.cancel() }

            return try await withTaskCancellationHandler(
                handler: { cancel() },
                operation: {
                    try await withCheckedThrowingContinuation { continuation in
                        dataTask = session.dataTask(with: request) { data, response, error in
                            guard let data = data, let response = response else {
                                continuation.resume(throwing: error ?? URLError(.badServerResponse))
                                return
                            }

                            continuation.resume(returning: (data, response))
                        }
                        if let parent = progress, let child = dataTask?.progress {
                            parent.addChild(child, withPendingUnitCount: 1)
                        }
                        dataTask?.resume()
                    }
                }
            )
        }
    }
}

extension NetworkTransport: HTTPLoadable {

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let urlRequest = URLRequest(data: request.data) else {
            throw HTTPError(.invalidRequest(.url), request: request)
        }
        do {
            let (data, urlResponse) = try await send(urlRequest, nil)
            let httpResponse = try createHTTPResponse(request: request, data: data, response: urlResponse)
            return httpResponse
        } catch {
            throw HTTPError(request: request, other: error)
        }
    }
}

internal extension NetworkTransport {

    func createHTTPResult(request: HTTPRequest, data: Data?, response: URLResponse?, error: Error?) -> HTTPResult {

        // Build an HTTP Response
        var httpResponse: HTTPResponse?

        if let response = response as? HTTPURLResponse {
            httpResponse = HTTPResponse(request: request, response: response, body: data)
        }

        // Check for errors
        if let error = error {
            let httpError = HTTPError(request: request, response: httpResponse, other: error)
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
