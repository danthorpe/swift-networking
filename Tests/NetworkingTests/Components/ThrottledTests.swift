import ConcurrencyExtras
import Dependencies
import Foundation
import Networking
import TestSupport
import XCTest

final class ThrottledTests: XCTestCase {

    func test__basics() async throws {
        let data = try XCTUnwrap("Hello".data(using: .utf8))
        let reporter = TestReporter()

        try await withDependencies {
            $0.shortID = .incrementing
            $0.continuousClock = TestClock()
        } operation: {
            try await withMainSerialExecutor {
                let request = HTTPRequestData(authority: "example.com")
                let network = TerminalNetworkingComponent()
                    .mocked(request, stub: .ok(data: data))
                    .reported(by: reporter)
                    .throttled(max: 5)

                try await withThrowingTaskGroup(of: HTTPResponseData.self) { group in
                    for _ in 0..<100 {
                        group.addTask {
                            try await network.data(HTTPRequestData(authority: "example.com"))
                        }
                    }

                    var responses: [HTTPResponseData] = []
                    for try await response in group {
                        responses.append(response)
                    }
                    XCTAssertEqual(responses.count, 100)
                }

                let peakActiveRequests = await reporter.peakActiveRequests
                XCTAssertEqual(peakActiveRequests, 5)
            }
        }
    }
}
