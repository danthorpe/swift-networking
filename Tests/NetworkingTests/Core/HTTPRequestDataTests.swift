import Dependencies
import ShortID
import Tagged
import XCTest

@testable import Networking

final class HTTPRequestDataTests: XCTestCase {
  override func invokeTest() {
    withDependencies {
      $0.shortID = .incrementing
    } operation: {
      super.invokeTest()
    }
  }

  func test__basics() {
    var request = HTTPRequestData(
      id: .init("some id"),
      method: .get,
      scheme: "https",
      authority: "example.com",
      path: "example",
      headerFields: [:],
      body: nil
    )

    XCTAssertEqual(request.id, Tagged<HTTPRequestData, String>(rawValue: "some id"))
    XCTAssertEqual(request.method, .get)
    XCTAssertEqual(request.scheme, "https")
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertEqual(request.path, "example")
    XCTAssertEqual(request.headerFields, [:])
    XCTAssertNil(request.body)

    request.method = .post
    XCTAssertEqual(request.method, .post)

    request.scheme = "abc"
    XCTAssertEqual(request.scheme, "abc")

    request.authority = "example.co.uk"
    XCTAssertEqual(request.authority, "example.co.uk")

    request.path = "example/another"
    XCTAssertEqual(request.path, "example/another")

    request.headerFields = [
      .contentType: "application/json",
      .accept: "application/json",
      .cacheControl: "no-cache",
    ]
    XCTAssertEqual(
      request.headerFields,
      [
        .contentType: "application/json",
        .accept: "application/json",
        .cacheControl: "no-cache",
      ])
    XCTAssertNil(request.body)
  }

  func test__short_id() {
    let request = HTTPRequestData(
      authority: "example.com"
    )
    XCTAssertEqual(request.identifier, "000001")
  }

  func test__options() {
    var request1 = HTTPRequestData(
      id: .init("some id"),
      authority: "example.com"
    )

    XCTAssertEqual(request1.testOption, "Hello World")
    request1.testOption = "Goodbye"
    XCTAssertEqual(request1.testOption, "Goodbye")

    var request2 = HTTPRequestData(
      id: .init("some id"),
      authority: "example.com"
    )

    // By default request options are not considered when
    // evaluating equality
    XCTAssertEqual(request1, request2)

    // Request options can override this behaviour, and signal that
    // they should be considered for equality
    request2.testEqualOption = "Goodbye"
    XCTAssertNotEqual(request1, request2)

    request1.testEqualOption = "Hello Again"
    XCTAssertNotEqual(request1, request2)

    request1.testEqualOption = "Goodbye"
    XCTAssertEqual(request1, request2)
  }

  func test__description() {
    var request = HTTPRequestData(
      id: .init("some id"),
      authority: "example.com"
    )
    XCTAssertEqual(request.debugDescription, "[0:some id] (GET) https://example.com/")

    request.scheme = "abc"
    request.method = .post
    request.path = "/hello"
    XCTAssertEqual(request.debugDescription, "[0:some id] (POST) abc://example.com/hello")
  }

  func test__foundation_url_request_with_path() throws {
    let request = HTTPRequestData(
      id: .init("some id"),
      method: .get,
      scheme: "https",
      authority: "example.com",
      path: "example",
      headerFields: [:],
      body: nil
    )

    let urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/example")
  }

  func test__foundation_url_request_minimum_arguments() throws {
    let request = HTTPRequestData(
      authority: "example.com"
    )

    let urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/")
  }
}

private struct TestOption: HTTPRequestDataOption {
  static var defaultOption: String = "Hello World"
}

extension HTTPRequestData {
  fileprivate var testOption: TestOption.Value {
    get { self[option: TestOption.self] }
    set { self[option: TestOption.self] = newValue }
  }
}

private struct TestEqualOption: HTTPRequestDataOption {
  static var defaultOption: String = "Hello World"
  static var includeInEqualityEvaluation: Bool { true }
}

extension HTTPRequestData {
  fileprivate var testEqualOption: TestEqualOption.Value {
    get { self[option: TestEqualOption.self] }
    set { self[option: TestEqualOption.self] = newValue }
  }
}
