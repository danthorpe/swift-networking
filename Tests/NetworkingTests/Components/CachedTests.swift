import Cache
import CustomDump
import Dependencies
import Foundation
import TestSupport
import XCTest

@testable import Networking

final class CachedTests: NetworkingTestCase {

  override func invokeTest() {
    withTestDependencies {
      $0.date = .constant(Date())
    } operation: {
      super.invokeTest()
    }
  }

  func test__basics() async throws {
    let reporter = TestReporter()
    let request = HTTPRequestData(id: "1", path: "message")

    let data = try XCTUnwrap("Hello".data(using: .utf8))
    let cache = Cache<HTTPRequestData, HTTPResponseData>(limit: 3)
    let network = TerminalNetworkingComponent()
      .mocked(request, stub: .ok(data: data))
      .reported(by: reporter)
      .cached(in: cache)

    var response = try await network.data(request)
    XCTAssertFalse(response.isCached)
    XCTAssertNil(response.cachedOriginalRequest?.id)
    XCTAssertNoDifference(String(data: response.data, encoding: .utf8), "Hello")

    response = try await network.data(request)
    XCTAssertTrue(response.isCached)
    XCTAssertEqual(response.cachedOriginalRequest?.id, "1")
    XCTAssertNoDifference(String(data: response.data, encoding: .utf8), "Hello")
  }

  func test__never_cache() async throws {
    let reporter = TestReporter()
    var request = HTTPRequestData(id: "1", path: "message")
    request.cacheOption = .never

    let data = try XCTUnwrap("Hello".data(using: .utf8))
    let cache = Cache<HTTPRequestData, HTTPResponseData>(limit: 3)
    let network = TerminalNetworkingComponent()
      .mocked(request, stub: .ok(data: data))
      .reported(by: reporter)
      .cached(in: cache)

    let response1 = try await network.data(request)
    XCTAssertFalse(response1.isCached)
    XCTAssertNil(response1.cachedOriginalRequest?.id)
    XCTAssertNoDifference(String(data: response1.data, encoding: .utf8), "Hello")

    let response2 = try await network.data(request)
    XCTAssertFalse(response2.isCached)
    XCTAssertNil(response2.cachedOriginalRequest?.id)
    XCTAssertNoDifference(String(data: response1.data, encoding: .utf8), "Hello")

    XCTAssertNoDifference(response1.request, response2.request)
    XCTAssertNoDifference(response1, response2)

    let executedRequestsCount = await reporter.requests.count
    XCTAssertEqual(executedRequestsCount, 2)
  }
}
