import Combine
import Foundation
import Helpers
import HTTPTypes
import HTTPTypesFoundation

@dynamicMemberLookup
public struct HTTPResponseData: Sendable {
    public let request: HTTPRequestData
    public let data: Data
    private let _response: HTTPResponse

    public subscript<Value>(
        dynamicMember dynamicMemberLookup: KeyPath<HTTPResponse, Value>
    ) -> Value {
        _response[keyPath: dynamicMemberLookup]
    }

    internal fileprivate(set) var metadata: [ObjectIdentifier: HTTPResponseMetadataContainer] = [:]

    public init(request: HTTPRequestData, data: Data, response: HTTPResponse) {
        self.request = request
        self.data = data
        self._response = response
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

// MARK: - Metadata

extension HTTPResponseData {
    public subscript<Metadata: HTTPResponseMetadata>(metadata metadataType: Metadata.Type) -> Metadata.Value {
        get {
            let id = ObjectIdentifier(metadataType)
            guard let container = metadata[id], let value = container.value as? Metadata.Value else {
                return metadataType.defaultMetadata
            }
            return value
        }
        set {
            let id = ObjectIdentifier(metadataType)
            metadata[id] = HTTPResponseMetadataContainer(
                newValue,
                isEqualTo: { other in
                    guard let other else {
                        return false == metadataType.includeInEqualityEvaluation
                    }
                    return metadataType.includeInEqualityEvaluation
                    ? _isEqual(newValue, other)
                    : true
                })
        }
    }

    internal mutating func copy(metadata other: [ObjectIdentifier: HTTPResponseMetadataContainer]) {
        self.metadata = other
    }
}

// MARK: - Conformances

extension HTTPResponseData: Equatable {
    public static func == (lhs: HTTPResponseData, rhs: HTTPResponseData) -> Bool {
        lhs.request == rhs.request
        && lhs.data == rhs.data
        && lhs._response == rhs._response
        && lhs.metadata.allSatisfy { key, lhs in
            return lhs.isEqualTo(rhs.metadata[key]?.value)
        }
        && rhs.metadata.allSatisfy { key, rhs in
            return rhs.isEqualTo(lhs.metadata[key]?.value)
        }
    }
}

extension HTTPResponseData: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(request)
        hasher.combine(data)
        hasher.combine(_response)
    }
}

extension HTTPResponseData: CustomDebugStringConvertible {
    public var debugDescription: String {
        var debugDescription = "\(self.status.description)"
        if data.isEmpty {
            debugDescription += " No Data"
        } else {
            if let contentType = self.headerFields[.contentType] {
                debugDescription += "\(contentType.description)"
                #if hasFeature(BareSlashRegexLiterals)
                let regex = /(json)/
                #else
                let regex = #/(json)/#
                #endif
                if contentType.contains(regex) {
                    let dataDescription = String(decoding: data, as: UTF8.self)
                    debugDescription += "\n\(dataDescription)"
                }
            }
        }
        return debugDescription
    }
}


// MARK: - Conveniences

extension HTTPResponse.Status {
    public var isFailure: Bool {
        Self.badRequest.code <= code
    }
}
