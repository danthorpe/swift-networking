import Combine
import Foundation
import HTTPTypes
import HTTPTypesFoundation

@dynamicMemberLookup
public struct HTTPResponseData: Hashable, Sendable {
    public let request: HTTPRequestData
    public let data: Data
    private let response: HTTPResponse

    public subscript<Value>(dynamicMember dynamicMemberLookup: KeyPath<HTTPResponse, Value>) -> Value {
        response[keyPath: dynamicMemberLookup]
    }

    public init(request: HTTPRequestData, data: Data, response: HTTPResponse) {
        self.request = request
        self.data = data
        self.response = response
    }

    public init(request: HTTPRequestData, data: Data, urlResponse: URLResponse?) throws {
        guard let response = (urlResponse as? HTTPURLResponse)?.httpResponse else {
            throw StackError.invalidURLResponse(request, data, urlResponse)
        }
        self.init(request: request, data: data, response: response)
    }

    func decode<Body, Decoder: TopLevelDecoder, Payload: Decodable>(
        as payloadType: Payload.Type,
        decoder: Decoder,
        transform: @Sendable (Payload, Self) throws -> Body
    ) throws -> Body where Decoder.Input == Data {
        do {
            let payload = try decoder.decode(payloadType, from: data)
            let body = try transform(payload, self)
            return body
        } catch let error as DecodingError {
            throw StackError.decodeResponse(self, error)
        }
    }
}

extension HTTPResponse.Status {
    public var isFailure: Bool {
        Self.badRequest.code <= code
    }
}
