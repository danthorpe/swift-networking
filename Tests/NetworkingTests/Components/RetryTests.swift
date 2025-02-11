import AssertionExtras
import Dependencies
import Foundation
import TestSupport
import Testing
import os.log

@testable import Networking

@Suite(.tags(.components))
struct RetryTests: TestableNetwork {

  @Test func test__basic_retry() async throws {
    let clock = ImmediateClock()
    let data = try #require("Hello".data(using: .utf8))
    let retryingMock = RetryingMock(
      stubs: [
        .init(.throwing, response: .init(status: .badGateway)),
        .init(.throwing, response: .init(status: .badGateway)),
        .ok(data: data),
      ]
    )

    let network = TerminalNetworkingComponent()
      .mocked { upstream, request in
        do {
          return try await retryingMock.send(upstream: upstream, request: request)
        } catch {
          XCTFail(String(describing: error))
          return .finished(throwing: error)
        }
      }
      .automaticRetry()
      .logged(using: .test)

    let response = try await withTestDependencies {
      $0.date = .constant(Date())
      $0.calendar = .current
      $0.continuousClock = clock
    } operation: {
      let request = HTTPRequestData()
      return try await network.data(request, timeout: .seconds(60), using: TestClock())
    }

    #expect(response.data == data)

    let stubs = await retryingMock.stubs
    #expect(stubs.isEmpty)
  }

  @Test func test__given_no_retry_strategy() {
    withTestDependencies {
      var request = HTTPRequestData()
      request.retryingStrategy = nil
    }
  }

  @Test func test__default_behaviour__constant_backoff() async {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    #expect(request.supportsRetryingRequests)
    let strategy = request.retryingStrategy
    var delay = await strategy?
      .retryDelay(
        request: request,
        after: [.failure("Some Error")],
        date: Date(),
        calendar: .current
      )
    #expect(delay == .seconds(3))
    delay = await strategy?
      .retryDelay(
        request: request,
        after: [.failure("Some Error"), .failure("Some Error")],
        date: Date(),
        calendar: .current
      )
    #expect(delay == .seconds(3))
    delay = await strategy?
      .retryDelay(
        request: request,
        after: [.failure("Some Error"), .failure("Some Error"), .failure("Some Error")],
        date: Date(),
        calendar: .current
      )
    #expect(delay == nil)
  }
}

@Suite
struct RetryStrategyTests: TestableNetwork {
  @Test func test_constant_backoff() async {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    let strategy = BackoffRetryStrategy.constant(delay: .seconds(1), maxAttemptCount: 3)
    var delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    #expect(delay == .seconds(1))
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    #expect(delay == .seconds(1))
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    #expect(delay == nil)
  }

  @Test func test_exponential_backoff() async {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    let strategy = BackoffRetryStrategy.exponential(maxDelay: .seconds(20), maxAttemptCount: 6)
    var delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    #expect(delay?.components.seconds == 2)
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    #expect(delay?.components.seconds == 4)
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    #expect(delay?.components.seconds == 8)
    delay = await strategy.retryDelay(
      request: request,
      after: [
        .failure("Some Error"), .failure("Some Error"), .failure("Some Error"),
        .failure("Some Error"),
      ],
      date: Date(),
      calendar: .current
    )
    #expect(delay?.components.seconds == 16)
    delay = await strategy.retryDelay(
      request: request,
      after: [
        .failure("Some Error"), .failure("Some Error"), .failure("Some Error"),
        .failure("Some Error"),
        .failure("Some Error"),
      ],
      date: Date(),
      calendar: .current
    )
    #expect(delay?.components.seconds == 20)
    delay = await strategy.retryDelay(
      request: request,
      after: [
        .failure("Some Error"), .failure("Some Error"), .failure("Some Error"),
        .failure("Some Error"),
        .failure("Some Error"), .failure("Some Error"),
      ],
      date: Date(),
      calendar: .current
    )
    #expect(delay == nil)
  }

  @Test func test_immediate_backoff() async {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    let strategy = BackoffRetryStrategy.immediate(maxAttemptCount: 3)
    var delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    #expect(delay == .zero)
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    #expect(delay == .zero)
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    #expect(delay == nil)
  }
}

#if swift(>=6)
extension String: @retroactive Error {}
#else
extension String: Error {}
#endif
