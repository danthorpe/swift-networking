import Dependencies
import Foundation
import Networking
import TestSupport
import Testing

@Suite(.tags(.components))
struct NumberedTests: TestableNetwork {

  actor RequestSequenceReporter: NetworkReportingComponent {
    var numbers: [(identifier: String, number: Int)] = []
    func didStart(request: HTTPRequestData) {
      numbers.append((request.identifier, RequestSequence.number))
    }
  }

  @Test func test__requests_get_incrementing_sequence_numbers() async throws {
    let reporter = RequestSequenceReporter()

    try await withTestDependencies {
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

      #expect(
        numbers.map(\.identifier) == [
          request1.identifier,
          request2.identifier,
          request1.identifier,
        ])
      #expect(numbers.map(\.number) == [1, 2, 3])
    }
  }
}
