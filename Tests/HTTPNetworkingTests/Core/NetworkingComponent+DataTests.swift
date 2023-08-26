import AssertionExtras
import Dependencies
import Foundation
import Helpers
import TestSupport
import XCTest
import ShortID

@testable import HTTPNetworking

final class NetworkingComponentDataTests: XCTestCase {

    func test__basic_data() async throws {
        try await withDependencies {
            $0.shortID = .incrementing
            $0.continuousClock = TestClock()
        } operation: {
            let request = HTTPRequestData(authority: "example.com")
            let data = try XCTUnwrap("Hello World".data(using: .utf8))
            let network = TerminalNetworkingComponent(isFailingTerminal: true)
                .mocked(request, stub: .ok(data: data))

            let response = try await network.data(request)

            XCTAssertEqual(response.data, data)
        }
    }

    func test__basic_data__timeout() async throws {
        let clock = TestClock()
        try await withDependencies {
            $0.shortID = .incrementing
            $0.continuousClock = clock
        } operation: {
            let request = HTTPRequestData(authority: "example.com")
            let data = try XCTUnwrap("Hello World".data(using: .utf8))
            let network = TerminalNetworkingComponent(isFailingTerminal: true)
                .mocked(request, stub: .ok(data: data))

            async let response = network.data(request, timeout: .seconds(2))
            await clock.advance(by: .seconds(3))
            do {
                _ = try await response.data
                XCTFail("Expected an error to be thrown.")
            } catch {
                XCTAssertEqual(error as? String, "TODO: Timeout Error")
            }
        }
    }
}
