import AssertionExtras
import Dependencies
import Foundation
import TestSupport
import XCTest
import os.log

@testable import Networking

final class RetryTests: XCTestCase {

  final class RetryingMock {
    var stubs: [StubbedResponseStream]
    init(stubs: [StubbedResponseStream]) {
      self.stubs = stubs.reversed()
    }

    func send(upstream: NetworkingComponent, request: HTTPRequestData) throws -> ResponseStream<
      HTTPResponseData
    > {
      guard let stub = stubs.popLast() else {
        throw "Exhausted supply of stub responses"
      }
      return stub(request)
    }
  }

  func test__basic_retry() async throws {
    let clock = ImmediateClock()
    let data = try XCTUnwrap("Hello".data(using: .utf8))
    let retryingMock = RetryingMock(
      stubs: [
        .init(.throwing, response: .init(status: .badGateway)),
        .init(.throwing, response: .init(status: .badGateway)),
        .ok(data: data),
      ]
    )

    try await withDependencies {
      $0.date = .constant(Date())
      $0.calendar = .current
      $0.shortID = .incrementing
      $0.continuousClock = clock
    } operation: {
      let request = HTTPRequestData()

      let network = TerminalNetworkingComponent()
        .mocked { upstream, request in
          do {
            return try retryingMock.send(upstream: upstream, request: request)
          } catch {
            XCTFail(String(describing: error))
            return .finished(throwing: error)
          }
        }
        .automaticRetry()
        .logged(using: .test)

      let response = try await network.data(request, timeout: .seconds(60), using: TestClock())

      XCTAssertEqual(response.data, data)
      XCTAssertTrue(retryingMock.stubs.isEmpty)
    }
  }

  func test__given_no_retry_strategy() async {
    withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      var request = HTTPRequestData()
      request.retryingStrategy = nil
    }
  }

  func test__default_behaviour__constant_backoff() async {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    XCTAssertTrue(request.supportsRetryingRequests)
    let strategy = request.retryingStrategy
    var delay = await strategy?
      .retryDelay(
        request: request,
        after: [.failure("Some Error")],
        date: Date(),
        calendar: .current
      )
    XCTAssertEqual(delay, .seconds(3))
    delay = await strategy?
      .retryDelay(
        request: request,
        after: [.failure("Some Error"), .failure("Some Error")],
        date: Date(),
        calendar: .current
      )
    XCTAssertEqual(delay, .seconds(3))
    delay = await strategy?
      .retryDelay(
        request: request,
        after: [.failure("Some Error"), .failure("Some Error"), .failure("Some Error")],
        date: Date(),
        calendar: .current
      )
    XCTAssertNil(delay)
  }
}

final class RetryStrategyTests: XCTestCase {
  func test_constant_backoff() async {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    let strategy = BackoffRetryStrategy.constant(delay: .seconds(1), maxAttemptCount: 3)
    var delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    XCTAssertEqual(delay, .seconds(1))
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    XCTAssertEqual(delay, .seconds(1))
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    XCTAssertNil(delay)
  }

  func test_exponential_backoff() async {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    let strategy = BackoffRetryStrategy.exponential(maxDelay: .seconds(20), maxAttemptCount: 6)
    var delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    XCTAssertEqual(delay?.components.seconds, 2)
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    XCTAssertEqual(delay?.components.seconds, 4)
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    XCTAssertEqual(delay?.components.seconds, 8)
    delay = await strategy.retryDelay(
      request: request,
      after: [
        .failure("Some Error"), .failure("Some Error"), .failure("Some Error"),
        .failure("Some Error"),
      ],
      date: Date(),
      calendar: .current
    )
    XCTAssertEqual(delay?.components.seconds, 16)
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
    XCTAssertEqual(delay?.components.seconds, 20)
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
    XCTAssertNil(delay)
  }

  func test_immediate_backoff() async {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    let strategy = BackoffRetryStrategy.immediate(maxAttemptCount: 3)
    var delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    XCTAssertEqual(delay, .zero)
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    XCTAssertEqual(delay, .zero)
    delay = await strategy.retryDelay(
      request: request,
      after: [.failure("Some Error"), .failure("Some Error"), .failure("Some Error")],
      date: Date(),
      calendar: .current
    )
    XCTAssertNil(delay)

  }
}

extension String: Error {}
