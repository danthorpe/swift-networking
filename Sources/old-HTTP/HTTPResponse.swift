//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation
import URLRouting

public struct HTTPResponse {
    public let request: URLRequestData
    public let body: Data?
    private let response: HTTPURLResponse

    public init(request: URLRequestData, response: HTTPURLResponse, body: Data?) {
        self.request = request
        self.response = response
        self.body = body
    }
}

public extension HTTPResponse {

    var status: HTTPStatus {
        HTTPStatus(response.statusCode)
    }

    var message: String {
        HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    }

    var headers: [AnyHashable: Any] {
        response.allHeaderFields
    }
}

public extension HTTPResponse {

    func validate(request: HTTPRequest? = nil) throws -> Data {
        guard status != .noContent else {
            return Data()
        }
        guard let data = body else {
            throw HTTPError(
                .bodyMalformed,
                request: request ?? self.request,
                response: self,
                underlyingError: HTTPResponseError.emptyBodyModelDecodingFailed
            )
        }

        return data
    }
}

public enum HTTPResponseError: Error {
    case emptyBodyModelDecodingFailed
}
