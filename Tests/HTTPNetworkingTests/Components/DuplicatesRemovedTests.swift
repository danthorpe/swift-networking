import ConcurrencyExtras
import Dependencies
import Foundation
import HTTPNetworking
import TestSupport
import XCTest

final class DuplicatesRemovedTests: XCTestCase {

    func test__duplicates_removed() async throws {
        let data1 = try XCTUnwrap("Hello".data(using: .utf8))
        let data2 = try XCTUnwrap("World".data(using: .utf8))
        let data3 = try XCTUnwrap("Whoops".data(using: .utf8))

        let reporter = TestReporter()

        try await withDependencies {
            $0.shortID = .incrementing
            $0.continuousClock = TestClock()
        } operation: {
            try await withMainSerialExecutor {
                let request1 = HTTPRequestData(authority: "example.com")
                let request2 = HTTPRequestData(authority: "example.co.uk")
                let request3 = HTTPRequestData(authority: "example.com", path: "/error")
                let request4 = HTTPRequestData(authority: "example.com") // actually the same endpoint as request 1

                let network = TerminalNetworkingComponent(isFailingTerminal: true)
                    .mocked(request1, stub: .ok(data: data1))
                    .mocked(request2, stub: .ok(data: data2))
                    .mocked(request3, stub: .ok(data: data3))
                    .mocked(request4, stub: .ok(data: data1))
                    .reported(by: reporter)
                    .duplicatesRemoved()
                    .logged(using: .test)

                try await withThrowingTaskGroup(of: HTTPResponseData.self) { group in
                    for _ in 0..<4 {
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
                    XCTAssertEqual(responses.count, 16)
                }

                let reportedRequests = await reporter.requests
                XCTAssertEqual(reportedRequests.count, 3)
            }
        }
    }
}
