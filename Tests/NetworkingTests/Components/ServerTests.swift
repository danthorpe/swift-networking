import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import XCTest
import os.log

@testable import Networking

final class ServerTests: XCTestCase {

  override func invokeTest() {
    withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      super.invokeTest()
    }
  }

  func test__set_authority_on_all_requests() async throws {
    let reporter = TestReporter()
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"
    headerFields[.cookie] = "cookie"

    let network = TerminalNetworkingComponent()
      .mocked(HTTPRequestData(authority: "sample.com"), stub: .ok())
      .reported(by: reporter)
      .server(authority: "sample.com")
      .logged(using: Logger())

    try await network.data(HTTPRequestData())

    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.authority), ["sample.com"])
  }

  func test__set_path_prefix_on_all_requests() async throws {
    let reporter = TestReporter()
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"
    headerFields[.cookie] = "cookie"

    let network = TerminalNetworkingComponent()
      .mocked(HTTPRequestData(authority: "sample.com", path: "/v1/hello"), stub: .ok())
      .reported(by: reporter)
      .server(prefixPath: "v1")
      .server(authority: "sample.com")
      .logged(using: Logger())

    try await network.data(HTTPRequestData(path: "hello"))

    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.authority), ["sample.com"])
    XCTAssertEqual(sentRequests.map(\.path), ["/v1/hello"])
  }

  func test__set_path_prefix_on_all_requests__with_empty_path() async throws {
    let reporter = TestReporter()
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"
    headerFields[.cookie] = "cookie"

    let network = TerminalNetworkingComponent()
      .mocked(HTTPRequestData(authority: "sample.com", path: "/v1"), stub: .ok())
      .reported(by: reporter)
      .server(prefixPath: "v1")
      .server(authority: "sample.com")
      .logged(using: Logger())

    try await network.data(HTTPRequestData())

    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.authority), ["sample.com"])
    XCTAssertEqual(sentRequests.map(\.path), ["/v1"])
  }

  func test__set_default_headers() async throws {
    let reporter = TestReporter()
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"

    let network = TerminalNetworkingComponent()
      .mocked(HTTPRequestData(authority: "sample.com", headerFields: headerFields), stub: .ok())
      .reported(by: reporter)
      .server(headerField: .contentType, value: "application/json")
      .server(authority: "sample.com")
      .logged(using: Logger())

    try await network.data(HTTPRequestData())

    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.authority), ["sample.com"])
    XCTAssertEqual(
      sentRequests.map(\.headerFields).compactMap { $0[.contentType] }, ["application/json"])
  }
}
