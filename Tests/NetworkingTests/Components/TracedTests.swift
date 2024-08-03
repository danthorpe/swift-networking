import Foundation
import TestSupport
import XCTest

@testable import Networking

final class TracedTests: NetworkingTestCase {
  override func invokeTest() {
    withTestDependencies {
      super.invokeTest()
    }
  }

  func test__request_includes_trace() async throws {
    let reporter = TestReporter()

    let network = TerminalNetworkingComponent()
      .mocked(all: .ok())
      .reported(by: reporter)
      .traced()

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

    let sentRequests = await reporter.requests

    XCTAssertEqual(
      sentRequests.map(\.headerFields[.traceparent]),
      [
        "00-0000000000000001-0000000000000001-01",
        "00-0000000000000002-0000000000000002-01",
        "00-0000000000000003-0000000000000003-01",
        "00-0000000000000004-0000000000000004-01",
        "00-0000000000000005-0000000000000005-01",
        "00-0000000000000006-0000000000000006-01",
        "00-0000000000000007-0000000000000007-01",
        "00-0000000000000008-0000000000000008-01",
        "00-0000000000000009-0000000000000009-01",
        "00-000000000000000a-000000000000000a-01",
      ]
    )

    XCTAssertEqual(sentRequests.last?.traceId, "000000000000000a")
    XCTAssertEqual(sentRequests.first?.parentId, "0000000000000001")
  }

  func test__traced_requests_do_not_get_another_trace() async throws {
    let reporter = TestReporter()

    let network = TerminalNetworkingComponent()
      .mocked(all: .ok())
      .reported(by: reporter)
      .traced()

    // Make an initial request
    let response = try await network.data(HTTPRequestData())

    // Resend the request
    try await network.data(response.request)

    let sentRequests = await reporter.requests

    XCTAssertEqual(
      sentRequests.map(\.headerFields[.traceparent]),
      [
        "00-0000000000000001-0000000000000001-01",
        "00-0000000000000001-0000000000000001-01",
      ]
    )
  }

  func test__live_trace_generator() async {
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

    XCTAssertEqual(Set(traces).count, 10)
  }
}
