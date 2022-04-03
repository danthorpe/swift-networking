//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public struct HTTPError: Error {

    public enum InvalidRequest: Equatable {
        case url
        case body
        case unknown
    }

    public enum Code: Equatable {
        case invalidRequest(InvalidRequest) // the HTTPRequest could not be turned into a URLRequest
        case cannotAuthenticate             // Failed to retrieve authentication credentials
        case cannotConnect                  // some sort of connectivity problem
        case cancelled                      // the user cancelled the request
        case insecureConnection             // couldn't establish a secure connection to the server
        case invalidResponse                // the system did not receive a valid HTTP response
        case timedOut                       // Request is timed out
        case authenticationFailed           // user authentication malformed/missing/rejected...
        case resetInProgress                // The chain of loader is being reset
        case bodyMalformed                  // The decoding of the Body Data failed
        case fileError                      // Error related to file
        case unknown                        // we have no idea what the problem is
    }

    public let code: Code
    public let request: HTTPRequest
    public let response: HTTPResponse?
    public let underlyingError: Error?

    internal init(_ code: HTTPError.Code, request: HTTPRequest, response: HTTPResponse? = nil, underlyingError: Error? = nil) {
        self.code = code
        self.request = request
        self.response = response
        self.underlyingError = underlyingError
    }
}

extension HTTPError: CustomStringConvertible {

    public var description: String {
        let underlyingErrorDescription = underlyingError.map { String(describing: $0) } ?? ""
        return "\(code) \(underlyingErrorDescription)"
    }
}
