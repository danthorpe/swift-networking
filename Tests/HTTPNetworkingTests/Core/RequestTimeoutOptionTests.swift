import Dependencies
import Foundation
import TestSupport
import XCTest

@testable import HTTPNetworking

final class RequestTimeoutOptionTests: XCTestCase {
    func test__request_timeout_option() {
        var request = HTTPRequestData(id: .init("1"), authority: "example.com")
        XCTAssertEqual(request.requestTimeoutInSeconds, 60)
        request.requestTimeoutInSeconds = 100
        XCTAssertEqual(request.requestTimeoutInSeconds, 100)
    }
}
