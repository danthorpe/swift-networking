import Dependencies
import Foundation
import HTTPNetworking
import ShortID
import TestSupport
import XCTest

final class RequestTests: XCTestCase {

    func test__decoder_basics() async throws {
        let json =
"""
{"value":"Hello World"}
"""
        let data = try XCTUnwrap(json.data(using: .utf8))

        try await withDependencies {
            $0.shortID = .incrementing
            $0.continuousClock = TestClock()
        } operation: {
            let http = HTTPRequestData(authority: "example.com")
            let network = TerminalNetworkingComponent()
                .mocked(http, stub: .ok(data: data))

            var (message, response) = try await network.value(Request<Message>(http: http))
            XCTAssertEqual(message.value, "Hello World")
            XCTAssertEqual(response.status, .ok)

            (message, response) = try await network.value(http, as: Message.self, decoder: JSONDecoder())
            XCTAssertEqual(message.value, "Hello World")
            XCTAssertEqual(response.status, .ok)
        }
    }
}

private struct Message: Decodable, Equatable {
    let value: String
}
