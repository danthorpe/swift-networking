import Combine
import Dependencies
import Foundation
import Helpers

/// `NetworkingComponent` is a protocol to enable a chain-of-responsibility style networking stack. The
/// stack is comprised of multiple elements, each of which conforms to this protocol.
public protocol NetworkingComponent {

  /// Send the networking request and receive a stream of events back.
  func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData>

  /// Get the final resolved request before it would be sent. This is very useful to query the overall networking stack
  func resolve(_ request: HTTPRequestData) -> HTTPRequestData
}

// MARK: - Default Implementations

extension NetworkingComponent {
  public func resolve(_ request: HTTPRequestData) -> HTTPRequestData {
    request
  }
}

public typealias ResponseStream<Value> = AsyncThrowingStream<Partial<Value, BytesReceived>, Error>


// MARK: - Codable Support

extension NetworkingComponent {

  public func value<Body: Decodable, Decoder: TopLevelDecoder>(
    _ request: HTTPRequestData,
    as bodyType: Body.Type,
    decoder specializedDecoder: Decoder
  ) async throws -> (body: Body, response: HTTPResponseData) where Decoder.Input == Data {
    try await value(Request<Body>(http: request, decoder: specializedDecoder))
  }

  public func value<Body>(
    _ request: Request<Body>
  ) async throws -> (body: Body, response: HTTPResponseData) {
    let response = try await data(request.http)
    try Task.checkCancellation()
    let body = try request.decode(response)
    return (body, response)
  }
}
