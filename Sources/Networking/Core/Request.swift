import Foundation
import HTTPTypes

public struct Request<Body>: Sendable {
  public let http: HTTPRequestData
  public let decode: @Sendable (HTTPResponseData) throws -> Body

  public init(http: HTTPRequestData, decode: @escaping @Sendable (HTTPResponseData) throws -> Body) {
    self.http = http
    self.decode = decode
  }
}

extension Request {
  public init<Payload: Decodable>(
    http: HTTPRequestData,
    as payloadType: Payload.Type,
    decoder: some Decoding<Data>,
    transform: @escaping @Sendable (Payload, HTTPResponseData) throws -> Body
  ) {
    self.init(http: http) { response in
      try response.decode(as: payloadType, decoder: decoder, transform: transform)
    }
  }

  public init<Payload: Decodable>(
    http: HTTPRequestData,
    as payloadType: Payload.Type,
    transform: @escaping @Sendable (Payload, HTTPResponseData) throws -> Body
  ) {
    self.init(http: http, as: payloadType, decoder: JSONDecoder(), transform: transform)
  }
}

extension Request where Body: Decodable {

  public init(
    http: HTTPRequestData,
    decoder: some Decoding<Data>
  ) {
    self.init(http: http, as: Body.self, decoder: decoder) { payload, _ in
      payload
    }
  }

  public init(http: HTTPRequestData) {
    self.init(http: http, decoder: JSONDecoder())
  }
}
