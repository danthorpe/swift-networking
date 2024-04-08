import Combine
import Foundation
import HTTPTypes
import HTTPTypesFoundation
import Helpers

@dynamicMemberLookup
public struct HTTPResponseData: Sendable {
  public private(set) var request: HTTPRequestData
  public let data: Data
  private let rawValue: HTTPURLResponse
  private let http: HTTPResponse

  public subscript<Value>(
    dynamicMember dynamicMemberLookup: KeyPath<HTTPResponse, Value>
  ) -> Value {
    http[keyPath: dynamicMemberLookup]
  }

  public var url: URL? {
    rawValue.url
  }

  internal fileprivate(set) var metadata: [ObjectIdentifier: HTTPResponseMetadataContainer] = [:]

  init(request: HTTPRequestData, data: Data, httpUrlResponse: HTTPURLResponse, httpResponse: HTTPResponse) {
    self.request = request
    self.data = data
    self.rawValue = httpUrlResponse
    self.http = httpResponse
  }

  public init(request: HTTPRequestData, data: Data, urlResponse: URLResponse?) throws {
    guard
      let httpUrlResponse = (urlResponse as? HTTPURLResponse),
      let httpResponse = httpUrlResponse.httpResponse
    else {
      throw StackError(invalidURLResponse: urlResponse, request: request, data: data)
    }
    self.init(request: request, data: data, httpUrlResponse: httpUrlResponse, httpResponse: httpResponse)
  }

  mutating func set(request newRequest: HTTPRequestData) {
    self.request = newRequest
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
      throw StackError(decodeResponse: self, error: error)
    }
  }
}

// MARK: - Metadata

extension HTTPResponseData {
  public subscript<Metadata: HTTPResponseMetadata>(metadata metadataType: Metadata.Type)
    -> Metadata.Value
  {
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
      && lhs.rawValue ~= rhs.rawValue  // HTTPURLResponse is a reference type
      && lhs.metadata.allSatisfy { key, lhs in
        lhs.isEqualTo(rhs.metadata[key]?.value)
      }
      && rhs.metadata.allSatisfy { key, rhs in
        rhs.isEqualTo(lhs.metadata[key]?.value)
      }
  }
}

extension HTTPResponseData: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(request)
    hasher.combine(data)
    hasher.combine(ObjectIdentifier(rawValue))
    hasher.combine(http)
  }
}

extension HTTPResponseData: CustomDebugStringConvertible {
  public var debugDescription: String {
    "\(self.status.description)"
  }
}

// MARK: - Logging Helpers

extension HTTPResponseData {
  public var prettyPrintedHeaders: String {
    http.headerFields.prettyPrintedDescription(title: "📬 Response Headers")
  }

  public var prettyPrintedBody: String {
    data.prettyPrintedData
  }
}

// MARK: - Conveniences

extension HTTPResponse.Status {
  public var isSuccess: Bool {
    false == isFailure
  }
  public var isFailure: Bool {
    switch kind {
    case .clientError, .serverError:
      return true
    default:
      return false
    }
  }
  public var isServerError: Bool {
    kind == .serverError
  }
}

extension Result where Success == HTTPResponseData, Failure: Error {
  public var httpRequest: HTTPRequestData? {
    switch self {
    case let .success(response):
      return response.request
    case let .failure(error):
      return error.httpRequest
    }
  }
}

extension Result where Success == HTTPResponseData, Failure: NetworkingError {
  public var request: HTTPRequestData {
    switch self {
    case let .success(response):
      return response.request
    case let .failure(error):
      return error.request
    }
  }
}

private func ~= (lhs: HTTPURLResponse, rhs: HTTPURLResponse) -> Bool {
  lhs.url == rhs.url
    && lhs.mimeType == rhs.mimeType
    && lhs.expectedContentLength == rhs.expectedContentLength
    && lhs.textEncodingName == rhs.textEncodingName
    && lhs.suggestedFilename == rhs.suggestedFilename
}

// MARK: - Error Handling

extension StackError {

  init(invalidURLResponse urlResponse: URLResponse?, request: HTTPRequestData, data: Data) {
    self.init(
      info: .request(request),
      kind: .invalidURLResponse(data, urlResponse),
      error: NoUnderlyingError()
    )
  }

  init(decodeResponse response: HTTPResponseData, error: Error) {
    self.init(info: .response(response), kind: .decodingResponse, error: error)
  }
}
