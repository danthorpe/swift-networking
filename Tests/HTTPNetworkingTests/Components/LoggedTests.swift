import AssertionExtras
import Dependencies
import Foundation
import HTTPNetworking
import TestSupport
import XCTest

final class LoggedTests: XCTestCase {

    struct OnSuccess: Equatable {
        let request: HTTPRequestData
        let response: HTTPResponseData
        let bytes: BytesReceived
    }

    struct OnFailure {
        let request: HTTPRequestData
        let error: Error
    }

    actor LoggedTester {
        var onSend: [HTTPRequestData] = []
        var onSuccess: [OnSuccess] = []
        var onFailure: [OnFailure] = []

        func appendSend(_ value: HTTPRequestData) {
            onSend.append(value)
        }
        func appendSuccess(_ value: OnSuccess) {
            onSuccess.append(value)
        }
        func appendFailure(_ value: OnFailure) {
            onFailure.append(value)
        }
    }

    func test__logged_receives_lifecycle() async throws {

        let tester = LoggedTester()
        let data1 = try XCTUnwrap("Hello".data(using: .utf8))
        let data2 = try XCTUnwrap("World".data(using: .utf8))
        let data3 = try XCTUnwrap("Whoops".data(using: .utf8))

        try await withDependencies {
            $0.shortID = .incrementing
            $0.continuousClock = TestClock()
        } operation: {
            let request1 = HTTPRequestData(authority: "example.com")
            let request2 = HTTPRequestData(authority: "example.co.uk")
            let request3 = HTTPRequestData(authority: "example.com", path: "error")
            let network = TerminalNetworkingComponent(isFailingTerminal: true)
                .mocked(request1, stub: .ok(data: data1))
                .mocked(request2, stub: .ok(data: data2))
                .mocked(request3, stub: .ok(.throwing, data: data3))
                .logged(using: .test) { [tester] in
                    await tester.appendSend($0)
                } onFailure: { [tester] in
                    await tester.appendFailure(OnFailure(request: $0, error: $1))
                } onSuccess: { [tester] in
                    await tester.appendSuccess(OnSuccess(request: $0, response: $1, bytes: $2))
                }

            try await network.data(request1)
            try await network.data(request2)
            try await network.data(request1)
            try await XCTAssertThrowsError(
                await network.data(request3),
                matches: StubbedError(request: request3)
            )

            let requests = await tester.onSend
            XCTAssertEqual(requests, [request1, request2, request1, request3])
            let datas = await tester.onSuccess.map(\.response.data)
            XCTAssertEqual(datas, [data1, data2, data1])
            let failureRequests = await tester.onFailure.map(\.request)
            XCTAssertEqual(failureRequests, [request3])
            let failureErrors = await tester.onFailure.map(\.error)
            XCTAssertEqual(failureErrors.compactMap { $0 as? StubbedError }, [StubbedError(request: request3)])
        }
    }
}
