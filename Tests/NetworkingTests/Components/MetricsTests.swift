import ConcurrencyExtras
import CustomDump
import Dependencies
import Foundation
import Networking
import TestSupport
import XCTest

final class MetricsTests: XCTestCase {
  func test__basics() async throws {
    let clock = TestClock()
    let data = try XCTUnwrap("Hello".data(using: .utf8))
    let reporter = NetworkEnvironmentReporter(keyPath: \.instrument)
    try await withDependencies {
      $0.shortID = .incrementing
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
      
      XCTAssertEqual(receivedData, data)
      
      guard let measurements = await reporter.finish??.elapsedTimeMeasurements() else {
        XCTFail("Expected to have elapsed time measurements")
        return
      }
      
      XCTAssertNoDifference(measurements.map(\.label), ["Delay", "Mocked"])
      XCTAssertNoDifference(measurements.map(\.duration), [.zero, .seconds(3)])
    }
  }
}
