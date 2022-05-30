import Foundation
import URLRouting

public struct URLResponseData {
    public let request: URLRequestData
    public let data: Data
    public let response: HTTPURLResponse

    public init(
        request: URLRequestData,
        data: Data,
        response: HTTPURLResponse
    ) {
        self.request = request
        self.data = data
        self.response = response
    }

    public init(
        request: URLRequestData,
        data: Data,
        response: URLResponse
    ) throws {
        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError(.invalidResponse, request: request, data: data)
        }
        self.init(
            request: request,
            data: data,
            response: response
        )
    }

    var deconstructed: (data: Data, response: HTTPURLResponse) {
        (data, response)
    }
}

public extension URLResponseData {

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
