import Dependencies
import Foundation
import Helpers

extension NetworkingComponent {

  /// Access the response as raw data.
  ///
  /// - Parameters:
  ///   - request: ``HTTPRequestData`` to send
  ///   - updateProgress: an escaping closure which is called periodically with a ``BytesReceived`` argument.
  ///   This can be used to drive a progress indicator. It has a default no-op value.
  /// - Throws: ``NetworkingError`` in the event of a timeout, or underlying network issue.
  /// - Returns: ``HTTPResponseData``
  @discardableResult public func data(
    _ request: HTTPRequestData,
    progress updateProgress: @escaping @Sendable (BytesReceived) async -> Void = { _ in }
  ) async throws -> HTTPResponseData {
    try await data(
      request,
      progress: updateProgress,
      timeout: .seconds(request.requestTimeoutInSeconds)
    )
  }

  /// Access the response as raw data with defined timeout.
  ///
  /// - Parameters:
  ///   - request: ``HTTPRequestData`` to send
  ///   - updateProgress: an escaping closure which is called periodically with a ``BytesReceived`` argument.
  ///   This can be used to drive a progress indicator. It has a default no-op value.
  ///   - duration: if the request takes longer than this `Duration` to finish, an error will be thrown.
  /// - Throws: ``NetworkingError`` in the event of a timeout, or underlying network issue.
  /// - Returns: ``HTTPResponseData``
  @discardableResult public func data(
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

  /// Access the response as raw data.
  ///
  /// This is a "low-level" API which we do not expect library consumers to use directly,
  /// as it requires a Clock.
  ///
  /// - Parameters:
  ///   - request: ``HTTPRequestData`` to send
  ///   - updateProgress: an escaping closure which is called periodically with a ``BytesReceived`` argument.
  ///   This can be used to drive a progress indicator. It has a default no-op value.
  ///   - duration: if the request takes longer than this `Duration` to finish, an error will be thrown.
  ///   - clock: in order to measure the timeout, a swift clock is required.
  /// - Throws: ``NetworkingError`` in the event of a timeout, or underlying network issue.
  /// - Returns: ``HTTPResponseData``
  @discardableResult package func data(
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
      throw StackError(timeout: request)
    }
  }
}

// MARK: - Error Handling

extension StackError {

  init(timeout request: HTTPRequestData) {
    self.init(
      info: .request(request),
      kind: .timeout,
      error: NoUnderlyingError()
    )
  }
}
