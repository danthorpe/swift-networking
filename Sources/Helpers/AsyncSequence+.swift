import Dependencies
import Foundation

// Stream into

extension AsyncSequence {
  public typealias ProcessElement = @Sendable (Element) async -> Void
  public typealias ProcessError = @Sendable (Error) async -> Void
  public typealias OnTermination = @Sendable () async -> Void

  public func redirect(
    into continuation: AsyncThrowingStream<Element, Error>.Continuation,
    onElement processElement: ProcessElement? = nil,
    onError processError: ProcessError? = nil,
    onTermination: OnTermination? = nil
  ) async {
    do {
      for try await element in self {
        continuation.yield(element)
        await processElement?(element)
      }
      continuation.finish()
      await onTermination?()
    } catch {
      await processError?(error)
      continuation.finish(throwing: error)
      await onTermination?()
    }
  }
}

// MARK: Timeouts

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension AsyncSequence {
  public func first(beforeTimeout duration: Duration, using clock: any Clock<Duration>) async throws
    -> Element {
    try await first(beforeTimeout: duration, using: clock, where: { _ in true })
  }

  public func first(
    beforeTimeout duration: Duration,
    using clock: any Clock<Duration>,
    where predicate: @escaping (Element) async throws -> Bool
  ) async throws -> Element {
    try await withTimeout(after: duration, using: clock) {
      guard let element = try await first(where: predicate) else {
        throw CancellationError()
      }
      return element
    }
  }
}

@available(macOS, deprecated: 13.0)
@available(iOS, deprecated: 16.0)
@available(watchOS, deprecated: 9.0)
@available(tvOS, deprecated: 16.0)
extension AsyncSequence {
  public func first(beforeTimeout timeInterval: TimeInterval) async throws -> Element {
    try await first(beforeTimeout: timeInterval, where: { _ in true })
  }

  public func first(
    beforeTimeout timeInterval: TimeInterval,
    where predicate: @escaping (Element) async throws -> Bool
  ) async throws -> Element {
    try await withTimeout(after: timeInterval) {
      guard let element = try await first(where: predicate) else {
        throw CancellationError()
      }
      return element
    }
  }
}
