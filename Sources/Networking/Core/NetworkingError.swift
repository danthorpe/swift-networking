import Foundation
import URLRouting

public struct NetworkingError: Error {

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
        case exhaustedLoaders               // Executed all of the loaders, but a response was not returned
        case unknown                        // we have no idea what the problem is
    }

    public let code: Code
    public let request: URLRequestData
    public let response: URLResponse?
    public let data: Data?
    public let underlyingError: Error?

    internal init(_ code: Self.Code, request: URLRequestData, response: URLResponse? = nil, data: Data? = nil, underlyingError: Error? = nil) {
        self.code = code
        self.request = request
        self.response = response
        self.data = data
        self.underlyingError = underlyingError
    }

    internal init(request: URLRequestData, response: URLResponse? = nil, data: Data? = nil, other error: Error) {
        if let networkingError = error as? NetworkingError {
            self = networkingError
        }

        // Check for a URLError
        else if let urlError = error as? URLError {
            let code: Self.Code
            switch urlError.code {
            case .badURL:
                code = .invalidRequest(.url)
            default:
                code = .unknown
            }

            self = .init(code, request: request, response: response, data: data, underlyingError: urlError)
        }

        // Unknown kind of error
        else {
            self = .init(.unknown, request: request, response: response, data: data, underlyingError: error)
        }
    }
}
