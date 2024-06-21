import AssertionExtras
import CustomDump
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import XCTest
import os.log

@testable import Networking

final class ServerTests: NetworkingTestCase {

  override func invokeTest() {
    withTestDependencies {
      super.invokeTest()
    }
  }

  func test__set_scheme() async throws {
    let reporter = TestReporter()
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"
    headerFields[.cookie] = "cookie"

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(scheme: "http")
      .logged(using: Logger())

    try await network.data(HTTPRequestData())

    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.scheme), ["http"])
  }

  func test__set_authority() async throws {
    let reporter = TestReporter()
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"
    headerFields[.cookie] = "cookie"

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(authority: "sample.com")
      .logged(using: Logger())

    try await network.data(HTTPRequestData())

    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.authority), ["sample.com"])

    XCTAssertEqual(network.authority, "sample.com")
  }

  func test__set_path() async throws {
    let reporter = TestReporter()
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"
    headerFields[.cookie] = "cookie"

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(path: "hello-world")
      .server(authority: "sample.com")
      .logged(using: Logger())

    try await network.data(HTTPRequestData(path: "hello"))

    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.authority), ["sample.com"])
    XCTAssertEqual(sentRequests.map(\.path), ["/hello-world"])
  }

  func test__set_path_prefix() async throws {
    let reporter = TestReporter()
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"
    headerFields[.cookie] = "cookie"

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(prefixPath: "v1")
      .server(authority: "sample.com")
      .logged(using: Logger())

    try await network.data(HTTPRequestData(path: "hello"))

    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.authority), ["sample.com"])
    XCTAssertEqual(sentRequests.map(\.path), ["/v1/hello"])
  }

  func test__set_path_prefix__with_empty_path() async throws {
    let reporter = TestReporter()
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"
    headerFields[.cookie] = "cookie"

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(prefixPath: "v1")
      .server(authority: "sample.com")
      .logged(using: Logger())

    try await network.data(HTTPRequestData())

    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.authority), ["sample.com"])
    XCTAssertEqual(sentRequests.map(\.path), ["/v1"])
  }

  func test__set_headers() async throws {
    let reporter = TestReporter()

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(headerField: .contentType, "application/json")
      .logged(using: Logger())

    try await network.data(HTTPRequestData())

    let sentRequestsHeaders = await reporter.requests.map(\.headerFields)
    XCTAssertEqual(
      sentRequestsHeaders.compactMap { $0[.contentType] },
      ["application/json"]
    )
  }

  func test__set_custom_headers() async throws {
    let reporter = TestReporter()

    let customFieldName = try XCTUnwrap(HTTPField.Name("X-CUSTOM-HEADER"))

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(customHeaderField: customFieldName.rawName, "custom-value")
      .logged(using: Logger())

    try await network.data(HTTPRequestData())
    let sentRequestsHeaders = await reporter.requests.map(\.headerFields)

    XCTAssertEqual(
      sentRequestsHeaders,
      [
        HTTPFields([HTTPField(name: customFieldName, value: "custom-value")])
      ])
  }

  func test__set_custom_header__invalid_header_name() async throws {
    let reporter = TestReporter()

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(customHeaderField: "", "value-for-invalid-header-name")
      .logged(using: Logger())

    try await network.data(HTTPRequestData())
    let sentRequestsHeaders = await reporter.requests.map(\.headerFields)
    XCTAssertEqual(sentRequestsHeaders, [HTTPFields() /* expect empty fields */])
  }

  func test__set_query_items_allow_characters() async throws {
    let reporter = TestReporter()

    let allowedCharacters: CharacterSet = .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+"))

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(queryItemsAllowedCharacters: allowedCharacters)
      .logged(using: Logger())

    try await network.data(HTTPRequestData(path: "?message=hello+world"))
    let sentRequestsURL = await reporter.requests.first?.url

    XCTAssertNoDifference(sentRequestsURL, URL(static: "https://example.com/?message=hello%2Bworld"))
  }

  func test__set_server_mutation_option__disabled() async throws {
    let reporter = TestReporter()

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .server(authority: "sample.com")
      .logged(using: Logger())

    var request = HTTPRequestData(authority: "api-sample.com", path: "auth")
    request.serverMutations = .disabled

    try await network.data(request)
    let sentRequests = await reporter.requests
    XCTAssertEqual(sentRequests.map(\.authority), ["api-sample.com"])
    XCTAssertEqual(sentRequests.map(\.path), ["/auth"])
  }
}
