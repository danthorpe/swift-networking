import Foundation
import HTTPTypes

public struct Request<Response>: Sendable {
  public let http: HTTPRequestData
  public let decode: @Sendable (HTTPResponseData) throws -> Response

  public init(http: HTTPRequestData, decode: @escaping @Sendable (HTTPResponseData) throws -> Response) {
    self.http = http
    self.decode = decode
  }
}

extension Request {
  public init<Payload: Decodable>(
    http: HTTPRequestData,
    as payloadType: Payload.Type,
    decoder: some Decoding<Data>,
    transform: @escaping @Sendable (Payload, HTTPResponseData) throws -> Response
  ) {
    self.init(http: http) { response in
      try response.decode(as: payloadType, decoder: decoder, transform: transform)
    }
  }

  public init<Payload: Decodable>(
    http: HTTPRequestData,
    as payloadType: Payload.Type,
    transform: @escaping @Sendable (Payload, HTTPResponseData) throws -> Response
  ) {
    self.init(http: http, as: payloadType, decoder: JSONDecoder(), transform: transform)
  }
}

extension Request where Response: Decodable {

  public init(
    http: HTTPRequestData,
    decoder: some Decoding<Data>
  ) {
    self.init(http: http, as: Response.self, decoder: decoder) { payload, _ in
      payload
    }
  }

  public init(http: HTTPRequestData) {
    self.init(http: http, decoder: JSONDecoder())
  }
}

extension Request {
  @available(*, deprecated, renamed: "Response", message: "The Body type parameter has been renamed Response")
  public typealias Body = Response
}
