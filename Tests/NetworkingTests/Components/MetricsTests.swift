import ConcurrencyExtras
import CustomDump
import Dependencies
import Foundation
import Networking
import TestSupport
import Testing

@Suite
struct MetricsTests: TestableNetwork {

  @Test func test__basics() async throws {
    let clock = TestClock()
    let data = try #require("Hello".data(using: .utf8))
    let reporter = NetworkEnvironmentReporter(keyPath: \.instrument)

    try await withTestDependencies {
      $0.continuousClock = clock
    } operation: {
      let request1 = HTTPRequestData(authority: "example.com")
      let network = TerminalNetworkingComponent()
        .mocked(request1, stub: .ok(data: data))
        .delayed(by: .seconds(3))
        .reported(by: reporter)
        .instrument()

      async let response = network.data(request1)
      await clock.advance(by: .seconds(3))
      let receivedData = try await response.data

      #expect(receivedData == data)
    }

    guard let measurements = await reporter.finish??.elapsedTimeMeasurements() else {
      Issue.record("Expected to have elapsed time measurements")
      return
    }

    #expect(measurements.map(\.label) == ["Delay"])
    #expect(measurements.map(\.duration) == [.zero])
  }
}
