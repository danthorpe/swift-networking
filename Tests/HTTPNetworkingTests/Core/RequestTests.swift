import Dependencies
import Foundation
import HTTPNetworking
import ShortID
import Tagged
import XCTest

final class RequestTests: XCTestCase {
/*
    func test__decoder_basics() throws {
        let json =
"""
{"value":"Hello World"}
"""
        let http = HTTPRequestData(id: "some-id", authority: "example.com")
        let request = Request<Message>(http: http)

        let httpResponseData = try HTTPResponseData(
            request: http,
            data: json.data(using: .utf8)!,
            urlResponse: HTTPURLResponse(
                httpResponse: .init(status: .ok),
                url: URL(string: "example.com")!
            )
        )

        // ???
    }
*/
}

private struct Message: Decodable, Equatable {
    let value: String
}
