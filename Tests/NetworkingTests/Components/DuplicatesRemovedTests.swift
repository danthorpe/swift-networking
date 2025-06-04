import ConcurrencyExtras
import Dependencies
import Foundation
import Networking
import TestSupport
import Testing

@Suite(.tags(.components))
struct DuplicatesRemovedTests: TestableNetwork {

  @Test func test__duplicates_removed() async throws {
    let data1 = try #require("Hello".data(using: .utf8))
    let data2 = try #require("World".data(using: .utf8))
    let data3 = try #require("Whoops".data(using: .utf8))

    let reporter = TestReporter()

    try await withTestDependencies {
      let request1 = HTTPRequestData(authority: "example.com")
      let request2 = HTTPRequestData(authority: "example.co.uk")
      let request3 = HTTPRequestData(authority: "example.com", path: "/error")
      let request4 = HTTPRequestData(authority: "example.com")  // actually the same endpoint as request 1

      let network = TerminalNetworkingComponent()
        .mocked(request1, stub: .ok(data: data1))
        .mocked(request2, stub: .ok(data: data2))
        .mocked(request3, stub: .ok(data: data3))
        .mocked(request4, stub: .ok(data: data1))
        .reported(by: reporter)
        .duplicatesRemoved()

      try await withThrowingTaskGroup(of: HTTPResponseData.self) { group in
        for _ in 0 ..< 40 {
          group.addTask {
            try await network.data(request1)
          }
          group.addTask {
            try await network.data(request2)
          }
          group.addTask {
            try await network.data(request3)
          }
          group.addTask {
            try await network.data(request4)
          }
        }

        var responses: [HTTPResponseData] = []
        for try await response in group {
          responses.append(response)
        }
        #expect(responses.count == 160)
      }
    }

    let reportedRequests = await reporter.requests
    #expect(reportedRequests.count == 3)
  }
}
