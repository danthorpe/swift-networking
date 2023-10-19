import Foundation

public struct TimeoutError: Error, Hashable, Sendable {}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public func withTimeout<ReturnValue>(
  after duration: Duration,
  using clock: any Clock<Duration>,
  do work: @escaping @Sendable () async throws -> ReturnValue
) async throws -> ReturnValue {
  try await withTimeout(do: work) {
    try await clock.sleep(for: duration)
    try Task.checkCancellation()
    throw TimeoutError()
  }
}

@available(macOS, deprecated: 13.0)
@available(iOS, deprecated: 16.0)
@available(watchOS, deprecated: 9.0)
@available(tvOS, deprecated: 16.0)
public func withTimeout<ReturnValue>(
  after duration: TimeInterval,
  do work: @escaping @Sendable () async throws -> ReturnValue
) async throws -> ReturnValue {
  try await withTimeout(do: work) {
    try await Task.sleep(seconds: duration)
    try Task.checkCancellation()
    throw TimeoutError()
  }
}

private func withTimeout<ReturnValue>(
  do work: @escaping @Sendable () async throws -> ReturnValue,
  taskWhichTimesout: @escaping @Sendable () async throws -> ReturnValue
) async throws -> ReturnValue {
  guard let value = try await firstReturnValue(from: [work, taskWhichTimesout]) else {
    throw CancellationError()
  }
  return value
}

private func firstReturnValue<ReturnValue>(
  from tasks: [@Sendable () async throws -> ReturnValue]
) async throws -> ReturnValue? {
  try await withThrowingTaskGroup(of: ReturnValue.self) { group in
    for task in tasks {
      group.addTask(operation: task)
    }
    let result = try await group.next()
    group.cancelAll()
    return result
  }
}

extension Task where Success == Never, Failure == Never {
  fileprivate static func sleep(seconds: TimeInterval) async throws {
    let duration = UInt64(seconds * Double(NSEC_PER_SEC))
    try await Task.sleep(nanoseconds: duration)
  }
}
