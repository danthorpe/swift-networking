import AssertionExtras
import Dependencies
import Foundation
import Helpers
import ShortID
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct NetworkingComponentDataTests: TestableNetwork {

  @Test func test__basic_data() async throws {
    try await withTestDependencies {
      let request = HTTPRequestData(authority: "example.com")
      let data = try #require("Hello World".data(using: .utf8))
      let network = TerminalNetworkingComponent()
        .mocked(request, stub: .ok(data: data))
      let response = try await network.data(request)
      #expect(response.data == data)
    }
  }

  @Test func test__basic_data__timeout() async throws {
    let clock = TestClock()
    try await withTestDependencies {
      $0.continuousClock = clock
    } operation: {
      let request = HTTPRequestData(authority: "example.com")
      let data = try #require("Hello World".data(using: .utf8))
      let network = TerminalNetworkingComponent()
        .mocked(request, stub: .ok(data: data))

      async let response = network.data(request, timeout: .seconds(2))
      await clock.advance(by: .seconds(3))
      do {
        _ = try await response.data
        Issue.record("Expected an error to be thrown.")
      } catch let error as StackError {
        #expect(error == StackError(timeout: request))
      } catch {
        Issue.record("Unexpected error \(error)")
      }
    }
  }

  @Test func test__basic_data_progress() async throws {
    actor UpdateProgress {
      var bytesReceived: [BytesReceived] = []
      func update(_ bytesReceived: BytesReceived) {
        self.bytesReceived.append(bytesReceived)
      }
    }
    let progress = UpdateProgress()

    try await withTestDependencies {
      let request = HTTPRequestData(authority: "example.com")
      let data = try #require("Hello World".data(using: .utf8))
      let network = TerminalNetworkingComponent()
        .mocked(request, stub: .ok(data: data))

      try await confirmation(expectedCount: 5) { confirmation in
        let response = try await network.data(request) { bytesReceived in
          confirmation()
          await progress.update(bytesReceived)
        }
        #expect(response.data == data)
      }

      let bytesReceived = await progress.bytesReceived
      #expect(
        bytesReceived == [
          BytesReceived(received: 2, expected: 11),
          BytesReceived(received: 4, expected: 11),
          BytesReceived(received: 6, expected: 11),
          BytesReceived(received: 8, expected: 11),
          BytesReceived(received: 11, expected: 11),
        ])
    }
  }
}
