import ConcurrencyExtras
import Dependencies
import ShortID

public protocol TestableNetwork {

  @discardableResult
  func withTestDependencies<R>(
    _ updateValuesForOperation: (inout DependencyValues) -> Void,
    operation: () throws -> R
  ) rethrows -> R

  @discardableResult
  func withTestDependencies<R>(
    _ updateValuesForOperation: (inout DependencyValues) -> Void,
    operation: () async throws -> R
  ) async rethrows -> R
}

extension TestableNetwork {

  @discardableResult
  public func withTestDependencies<R>(
    _ updateValuesForOperation: (inout DependencyValues) -> Void = { _ in },
    operation: () throws -> R
  ) rethrows -> R {
    try withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
      updateValuesForOperation(&$0)
    } operation: {
      try operation()
    }
  }

  @discardableResult
  public func withTestDependencies<R>(
    _ updateValuesForOperation: (inout DependencyValues) -> Void = { _ in },
    operation: () async throws -> R
  ) async rethrows -> R {
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
      updateValuesForOperation(&$0)
    } operation: {
      try await operation()
    }
  }

  public func withTestDependencies(
    _ updateValuesForOperation: (inout DependencyValues) -> Void = { _ in },
    operation: @Sendable () async throws -> Void
  ) async rethrows -> Void {
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
      updateValuesForOperation(&$0)
    } operation: {
      try await withMainSerialExecutor {
        try await operation()
      }
    }
  }
}
