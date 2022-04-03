import Combine
import Foundation

public struct Request<Body> {
    public typealias DecodingTask = (HTTPResponse) async throws -> Response<Body>
    public let http: HTTPRequest
    public let decode: DecodingTask

    public init(_ http: HTTPRequest, decode: @escaping DecodingTask) {
        self.http = http
        self.decode = decode
    }
}

extension Request where Body: Decodable {

    public init(json http: HTTPRequest, decoder: JSONDecoder = JSONDecoder()) {
        self.init(http, decoder: decoder)
    }

    public init<Decoder: TopLevelDecoder>(_ http: HTTPRequest, decoder: Decoder) where Decoder.Input == Data {
        self.init(http) { response in
            let data = try response.validate(request: http)
            let body = try decoder.decode(Body.self, from: data)
            return Response(http: response, body: body)
        }
    }
}
