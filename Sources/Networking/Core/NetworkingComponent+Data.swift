import Dependencies
import Foundation
import Helpers

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
    try await data(
      request, progress: updateProgress, timeout: .seconds(request.requestTimeoutInSeconds))
  }
}
