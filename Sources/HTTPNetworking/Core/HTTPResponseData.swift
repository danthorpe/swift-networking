import Combine
import Foundation
import HTTPTypes
import HTTPTypesFoundation

public struct HTTPResponseData: Hashable, Sendable {
    public let request: HTTPRequestData
    public let data: Data
    private let _response: HTTPResponse

    public init(request: HTTPRequestData, data: Data, urlResponse: URLResponse?) throws {
        guard let response = (urlResponse as? HTTPURLResponse)?.httpResponse else {
            throw "TODO: Failed to convert URLResponse to HTTPResponseData"
        }
        self.request = request
        self.data = data
        self._response = response
    }

    func decode<Body, Decoder: TopLevelDecoder, Payload: Decodable>(
        data: Data?,
        as payloadType: Payload.Type,
        decoder: Decoder,
        transform: @Sendable (Payload, Self) throws -> Body
    ) throws -> Body where Decoder.Input == Data {
        guard let data else {
            throw "TODO: Missing Data"
        }
        do {
            let payload = try decoder.decode(payloadType, from: data)
            let body = try transform(payload, self)
            return body
        } catch let error as DecodingError {
            throw "TODO: Decoding Error"
        }
    }
}
