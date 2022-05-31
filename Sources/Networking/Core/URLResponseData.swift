import Foundation
import URLRouting

public struct URLResponseData {
    public let request: URLRequestData
    public let data: Data
    public let response: URLResponse

    public init(
        request: URLRequestData,
        data: Data,
        response: URLResponse
    ) throws {
        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError(.invalidResponse, request: request, data: data)
        }
        self.request = request
        self.data = data
        self.response = response
    }

    var deconstructed: (data: Data, response: HTTPURLResponse) {
        (data, http)
    }
}

public extension URLResponseData {

    var http: HTTPURLResponse {
        response as! HTTPURLResponse
    }

    var status: HTTPStatus? {
        HTTPStatus(http.statusCode)
    }

    var message: String {
        HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
    }

    var headers: [AnyHashable: Any] {
        http.allHeaderFields
    }
}

extension URLResponseData: Codable {

    enum CodingKeys: CodingKey {
        case request, data, response
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let request = try container.decode(URLRequestData.self, forKey: .request)
        let data = try container.decode(Data.self, forKey: .data)
        let responseData = try container.decode(Data.self, forKey: .response)
        let response = try NSKeyedUnarchiver.unarchivedObject(ofClass: URLResponse.self, from: responseData)!
        try self.init(request: request, data: data, response: response)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(request, forKey: .request)
        try container.encode(data, forKey: .data)
        let responseData = try NSKeyedArchiver.archivedData(withRootObject: response, requiringSecureCoding: true)
        try container.encode(responseData, forKey: .response)
    }
}
