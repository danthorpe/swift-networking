import Foundation

extension NetworkingComponent {

  /// Make a request decoding the raw Data into the expected `Response` type.
  /// - See Also: ``value(_:)``
  /// - Parameter request: ``Request`` which is generic over some `Response`
  /// - Returns: the `Response` value.
  /// - Throws: ``NetworkingError``
  public func request<Response>(
    _ request: Request<Response>
  ) async throws -> Response {
    let http = try await data(request.http)
    try Task.checkCancellation()
    return try request.decode(http)
  }

  /// Make a request decoding the raw Data into the expected `Response` type using the decoder.
  /// - See Also: ``value(_:as:decoder:)``
  /// - Parameters:
  ///   - http: ``HTTPRequestData``
  ///   - responseType: a generic placeholder for a `Decodable` type
  ///   - specializedDecoder: a `TopLevelDecoder` where `Input` is `Data`
  /// - Returns: the `Response` value.
  /// - Throws: ``NetworkingError``
  public func request<Response: Decodable>(
    _ http: HTTPRequestData,
    as responseType: Response.Type,
    decoder: some Decoding<Data>
  ) async throws -> Response {
    try await request(Request<Response>(http: http, decoder: decoder))
  }
}
