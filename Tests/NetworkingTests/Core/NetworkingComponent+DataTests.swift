import AssertionExtras
import Dependencies
import Foundation
import Helpers
import ShortID
import TestSupport
import XCTest

@testable import Networking

final class NetworkingComponentDataTests: XCTestCase {

  func test__basic_data() async throws {
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      let request = HTTPRequestData(authority: "example.com")
      let data = try XCTUnwrap("Hello World".data(using: .utf8))
      let network = TerminalNetworkingComponent()
        .mocked(request, stub: .ok(data: data))

      let response = try await network.data(request)

      XCTAssertEqual(response.data, data)
    }
  }

  func test__basic_data__timeout() async throws {
    let clock = TestClock()
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = clock
    } operation: {
      let request = HTTPRequestData(authority: "example.com")
      let data = try XCTUnwrap("Hello World".data(using: .utf8))
      let network = TerminalNetworkingComponent()
        .mocked(request, stub: .ok(data: data))

      async let response = network.data(request, timeout: .seconds(2))
      await clock.advance(by: .seconds(3))
      do {
        _ = try await response.data
        XCTFail("Expected an error to be thrown.")
      } catch let error as StackError {
        XCTAssertEqual(error, StackError(timeout: request))
      } catch {
        XCTFail("Unexpected error \(error)")
      }
    }
  }

  func test__basic_data_progress() async throws {
    actor UpdateProgress {
      var bytesReceived: [BytesReceived] = []
      func update(_ bytesReceived: BytesReceived) {
        self.bytesReceived.append(bytesReceived)
      }
    }
    let progress = UpdateProgress()
    let progressExpectation = expectation(description: "Update progress")
    progressExpectation.assertForOverFulfill = true
    progressExpectation.expectedFulfillmentCount = 5

    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      let request = HTTPRequestData(authority: "example.com")
      let data = try XCTUnwrap("Hello World".data(using: .utf8))
      let network = TerminalNetworkingComponent()
        .mocked(request, stub: .ok(data: data))

      let response = try await network.data(request) { bytesReceived in
        progressExpectation.fulfill()
        await progress.update(bytesReceived)
      }
      XCTAssertEqual(response.data, data)
      await fulfillment(of: [progressExpectation])
      let bytesReceived = await progress.bytesReceived
      XCTAssertEqual(
        bytesReceived,
        [
          BytesReceived(received: 2, expected: 11),
          BytesReceived(received: 4, expected: 11),
          BytesReceived(received: 6, expected: 11),
          BytesReceived(received: 8, expected: 11),
          BytesReceived(received: 11, expected: 11),
        ])
    }

  }
}
