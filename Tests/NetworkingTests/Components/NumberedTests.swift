import Dependencies
import Foundation
import Networking
import TestSupport
import XCTest

final class NumberedTests: XCTestCase {
  
  actor RequestSequenceReporter: NetworkReportingComponent {
    var numbers: [(identifier: String, number: Int)] = []
    func didStart(request: HTTPRequestData) {
      numbers.append((request.identifier, RequestSequence.number))
    }
  }
  
  func test__requests_get_incrementing_sequence_numbers() async throws {
    let reporter = RequestSequenceReporter()
    
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      let request1 = HTTPRequestData(authority: "example.com")
      let request2 = HTTPRequestData(authority: "example.co.uk")
      let network = TerminalNetworkingComponent(isFailingTerminal: true)
        .mocked(request2, stub: .ok())
        .mocked(request1, stub: .ok())
        .reported(by: reporter)
        .numbered()
      
      try await network.data(request1)
      try await network.data(request2)
      try await network.data(request1)
      
      let numbers = await reporter.numbers
      
      XCTAssertEqual(numbers.map(\.identifier), [
        request1.identifier,
        request2.identifier,
        request1.identifier
      ])
      XCTAssertEqual(numbers.map(\.number), [1, 2, 3])
    }
  }
}
