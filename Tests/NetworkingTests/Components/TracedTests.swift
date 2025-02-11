import ConcurrencyExtras
import Dependencies
import Foundation
import TestSupport
import Testing

@testable import Networking

struct TracedTests: TestableNetwork {

  @Test(.tags(.components))
  func test__request_includes_trace() async throws {
    let reporter = TestReporter()

    let network = TerminalNetworkingComponent()
      .mocked(all: .ok())
      .reported(by: reporter)
      .traced()

    try await withTestDependencies {
      $0.traceParentGenerator = .incrementing
    } operation: {
      try await withThrowingTaskGroup(of: HTTPResponseData.self) { group in
        for _ in 0 ..< 10 {
          group.addTask {
            try await network.data(HTTPRequestData())
          }
        }

        var responses: [HTTPResponseData] = []
        for try await response in group {
          responses.append(response)
        }
      }
    }

    let sentRequests = await reporter.requests

    #expect(
      sentRequests.compactMap(\.traceId).sorted() == [
        "0000000000000001",
        "0000000000000002",
        "0000000000000003",
        "0000000000000004",
        "0000000000000005",
        "0000000000000006",
        "0000000000000007",
        "0000000000000008",
        "0000000000000009",
        "000000000000000a",
      ])

    #expect(
      sentRequests.compactMap(\.parentId).sorted() == [
        "0000000000000001",
        "0000000000000002",
        "0000000000000003",
        "0000000000000004",
        "0000000000000005",
        "0000000000000006",
        "0000000000000007",
        "0000000000000008",
        "0000000000000009",
        "000000000000000a",
      ])
  }

  @Test func test__traced_requests_do_not_get_another_trace() async throws {
    let reporter = TestReporter()

    let network = TerminalNetworkingComponent()
      .mocked(all: .ok())
      .reported(by: reporter)
      .traced()

    try await withTestDependencies {
      $0.traceParentGenerator = .incrementing
    } operation: {
      // Make an initial request
      let response = try await network.data(HTTPRequestData())

      // Resend the request
      try await network.data(response.request)
    }

    let sentRequests = await reporter.requests

    #expect(
      sentRequests.map(\.headerFields[.traceparent]) == [
        "00-0000000000000001-0000000000000001-01",
        "00-0000000000000001-0000000000000001-01",
      ])
  }

  @Test func test__live_trace_generator() async {
    let generate = TraceParentGenerator.liveValue

    let traces = await withTaskGroup(of: TraceParent.self) { group in
      for _ in 0 ..< 10 {
        group.addTask {
          generate()
        }
      }

      var traces: [TraceParent] = []
      for await trace in group {
        traces.append(trace)
      }
      return traces
    }

    #expect(Set(traces).count == 10)
  }
}
