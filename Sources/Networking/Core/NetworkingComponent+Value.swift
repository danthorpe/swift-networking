import Foundation

extension NetworkingComponent {

  /// Make a request decoding the raw Data into the expected `Body` type.
  /// - Parameter request: ``Request`` which is generic over some `Body`
  /// - Returns: a tuple of the body, and attendant ``HTTPResponseData``
  /// - Throws: ``NetworkingError``
  public func value<Body>(
    _ request: Request<Body>
  ) async throws -> (body: Body, response: HTTPResponseData) {
    let response = try await data(request.http)
    try Task.checkCancellation()
    let body = try request.decode(response)
    return (body, response)
  }

  /// Make a request decoding the raw Data into the provided `Body` using the decoder.
  /// - Parameters:
  ///   - request: ``HTTPRequestData``
  ///   - bodyType: a generic placeholder for a `Decodable` type
  ///   - specializedDecoder: a `TopLevelDecoder` where `Input` is `Data`
  /// - Returns: a tuple of the body, and attendant ``HTTPResponseData``
  /// - Throws: ``NetworkingError``
  public func value<Body: Decodable>(
    _ request: HTTPRequestData,
    as bodyType: Body.Type,
    decoder: some Decoding<Data>
  ) async throws -> (body: Body, response: HTTPResponseData) {
    try await value(Request<Body>(http: request, decoder: decoder))
  }
}
