import ConcurrencyExtras
import Dependencies
import Foundation
import Networking
import ShortID
import TestSupport
import Testing

@Suite(.tags(.components))
struct ThrottledTests: TestableNetwork {

  @Test func test__basics() async throws {
    let data = try #require("Hello".data(using: .utf8))
    let reporter = TestReporter()

    let network = TerminalNetworkingComponent()
      .mocked(all: .ok(data: data))
      .reported(by: reporter)
      .throttled(max: 5)

    let responses = try await withTestDependencies {
      try await withThrowingTaskGroup(of: HTTPResponseData.self, returning: [HTTPResponseData].self) { group in
        var responses: [HTTPResponseData] = []
        for _ in 0 ..< 100 {
          group.addTask {
            try await network.data(HTTPRequestData())
          }
        }
        for try await response in group {
          responses.append(response)
        }
        return responses
      }
    }

    #expect(responses.count == 100)

    let peakActiveRequests = await reporter.peakActiveRequests
    #expect(peakActiveRequests == 5)
  }
}
