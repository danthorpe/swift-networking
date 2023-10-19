import Combine
import Dependencies
import Foundation
import Helpers

/// `NetworkingComponent` is a protocol to enable a chain-of-responsibility style networking stack. The
/// stack is comprised of multiple elements, each of which conforms to this protocol.
///
/// It has a single requirement for sending a networking request, and receiving a stream of events back.
public protocol NetworkingComponent {
  func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData>
}

public typealias ResponseStream<Value> = AsyncThrowingStream<Partial<Value, BytesReceived>, Error>

extension NetworkingComponent {

  @discardableResult
  public func data(
    _ request: HTTPRequestData,
    progress updateProgress: @escaping @Sendable (BytesReceived) async -> Void = { _ in },
    timeout duration: Duration,
    using clock: @autoclosure () -> any Clock<Duration>
  ) async throws -> HTTPResponseData {
    do {
      try Task.checkCancellation()
      return try await send(request)
        .compactMap { element in
          await updateProgress(element.progress)
          return element.value
        }
        .first(beforeTimeout: duration, using: clock())
    } catch is TimeoutError {
      throw StackError.timeout(request)
    }
  }

  @discardableResult
  public func data(
    _ request: HTTPRequestData,
    progress updateProgress: @escaping @Sendable (BytesReceived) async -> Void = { _ in },
    timeout duration: Duration
  ) async throws -> HTTPResponseData {
    try await data(
      request,
      progress: updateProgress,
      timeout: duration,
      using: Dependency(\.continuousClock).wrappedValue
    )
  }

  @discardableResult
  public func data(
    _ request: HTTPRequestData,
    progress updateProgress: @escaping @Sendable (BytesReceived) async -> Void = { _ in }
  ) async throws -> HTTPResponseData {
    try await data(request, progress: updateProgress, timeout: .seconds(request.requestTimeoutInSeconds))
  }
}

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
