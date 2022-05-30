import Foundation
import URLRouting

public struct URLResponseData {
    public let request: URLRequestData
    public let data: Data?
    private let response: HTTPURLResponse
    public private(set) lazy var status = HTTPStatus(response.statusCode)

    public init(
        request: URLRequestData,
        data: Data?,
        response: HTTPURLResponse
    ) {
        self.request = request
        self.data = data
        self.response = response
    }
}

public extension URLResponseData {

    var message: String {
        HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    }

    var headers: [AnyHashable: Any] {
        response.allHeaderFields
    }
}
