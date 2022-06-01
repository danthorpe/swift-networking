import XCTest
@testable import Networking

final class HTTPStatusTests: XCTestCase {
    func test_success() async throws {
        XCTAssertTrue(HTTPStatus.ok.success)
        XCTAssertTrue(HTTPStatus.created.success)
        XCTAssertTrue(HTTPStatus.accepted.success)
        XCTAssertTrue(HTTPStatus.nonAuthoritativeInformation.success)
        XCTAssertTrue(HTTPStatus.noContent.success)
        XCTAssertTrue(HTTPStatus.resetContent.success)
        XCTAssertTrue(HTTPStatus.partialContent.success)
        XCTAssertTrue(HTTPStatus.multiStatus.success)
        XCTAssertTrue(HTTPStatus.alreadyReported.success)
        XCTAssertTrue(HTTPStatus.imUsed.success)
    }
}
