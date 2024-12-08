import ConcurrencyExtras
import Dependencies
import Foundation
import ShortID
import XCTest

@testable import Networking

open class NetworkingTestCase: XCTestCase {

  open var shortIdGenerator: ShortIDGenerator?
  open var continuousClock: (any Clock<Duration>)?

  open override func tearDown() {
    super.tearDown()
    shortIdGenerator = nil
    continuousClock = nil
  }

  public func withTestDependencies(
    _ updateValuesForOperation: (inout DependencyValues) -> Void = { _ in },
    operation: () -> Void
  ) {
    withDependencies {
      $0.shortID = shortIdGenerator ?? .incrementing
      $0.traceParentGenerator = .incrementing
      $0.continuousClock = continuousClock ?? TestClock()
      updateValuesForOperation(&$0)
    } operation: {
      withMainSerialExecutor {
        operation()
      }
    }
  }

  public func withTestDependencies(
    _ updateValuesForOperation: (inout DependencyValues) -> Void = { _ in },
    operation: @Sendable () async throws -> Void
  ) async throws {
    try await withDependencies {
      $0.shortID = shortIdGenerator ?? .incrementing
      $0.continuousClock = continuousClock ?? TestClock()
      updateValuesForOperation(&$0)
    } operation: {
      try await withMainSerialExecutor {
        try await operation()
      }
    }
  }
}
