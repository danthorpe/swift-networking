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

  func test__defaults() throws {
    let request = HTTPRequestData()
    let urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.method, .get)
    XCTAssertEqual(urlRequest.httpMethod, "GET")
    XCTAssertEqual(request.scheme, "https")
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(request.path, "/")
    XCTAssertNil(request.queryItems)
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/")
    XCTAssertEqual(request.headerFields, [:])
    XCTAssertNil(request.body)
  }

  func test__set_method() throws {
    var request = HTTPRequestData(method: .post)
    var urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.method, .post)
    XCTAssertEqual(urlRequest.httpMethod, "POST")
    request.method = .delete
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.method, .delete)
    XCTAssertEqual(urlRequest.httpMethod, "DELETE")
  }

  func test__set_scheme() throws {
    var request = HTTPRequestData(scheme: "http")
    var urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.scheme, "http")
    XCTAssertEqual(urlRequest.url?.absoluteString, "http://example.com/")
    request.scheme = "myapp"
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.scheme, "myapp")
    XCTAssertEqual(urlRequest.url?.absoluteString, "myapp://example.com/")
  }

  func test__set_authority() throws {
    var request = HTTPRequestData(authority: "hello.com")
    var urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "hello.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://hello.com/")

    request = HTTPRequestData(authority: "hello.com:1234")
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "hello.com:1234")
    XCTAssertEqual(request.port, 1234)
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://hello.com:1234/")

    request.authority = "goodbye.com"
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "goodbye.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://goodbye.com/")

    request.authority = "goodbye.com:1234"
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "goodbye.com:1234")
    XCTAssertEqual(request.port, 1234)
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://goodbye.com:1234/")
  }

  func test__set_path() throws {
    var request = HTTPRequestData(path: "example")
    var urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(request.path, "/example")
    XCTAssertNil(request.queryItems)
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/example")

    request.path = "another-example"
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(request.path, "/another-example")
    XCTAssertNil(request.queryItems)
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/another-example")

    request.path = "example?query=test"
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(request.path, "/example?query=test")
    XCTAssertEqual(request.queryItems, [URLQueryItem(name: "query", value: "test")])
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/example?query=test")

    request.path = "/"
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(request.path, "/?query=test")
    XCTAssertEqual(request.queryItems, [URLQueryItem(name: "query", value: "test")])
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/?query=test")
  }

  func test__set_query_items() throws {
    var request = HTTPRequestData(path: "example?query=test")
    var urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(request.path, "/example?query=test")
    XCTAssertEqual(request.queryItems, [URLQueryItem(name: "query", value: "test")])
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/example?query=test")
    request.anotherQuery = "hello"
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(request.path, "/example?query=test&anotherQuery=hello")
    XCTAssertEqual(request.queryItems, [
      URLQueryItem(name: "query", value: "test"),
      URLQueryItem(name: "anotherQuery", value: "hello"),
    ])
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/example?query=test&anotherQuery=hello")
    request.queryItems = nil
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertEqual(request.path, "/example")
    XCTAssertNil(request.queryItems)
    XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/example")
  }

  func test__set_url() throws {
    var request = HTTPRequestData()
    var urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(urlRequest.url, URL(static: "https://example.com/"))

    request.url = URL(static: "http://other.com:1234/some-path?message=Hello+World")
    urlRequest = try XCTUnwrap(URLRequest(http: request))
    XCTAssertEqual(request.scheme, "http")
    XCTAssertEqual(request.authority, "other.com:1234")
    XCTAssertEqual(request.port, 1234)
    XCTAssertEqual(request.path, "/some-path?message=Hello+World")
    XCTAssertEqual(request.queryItems, [URLQueryItem(name: "message", value: "Hello+World")])
    XCTAssertEqual(request.message, "Hello+World")
    XCTAssertEqual(urlRequest.url, URL(static: "http://other.com:1234/some-path?message=Hello+World"))
  }

  func test__basics() {
    var request = HTTPRequestData(
      method: .get,
      scheme: "https",
      authority: "example.com",
      path: "example",
      headerFields: [:],
      body: nil
    )

    XCTAssertEqual(request.method, .get)
    XCTAssertEqual(request.scheme, "https")
    XCTAssertEqual(request.authority, "example.com")
    XCTAssertEqual(request.path, "/example")
    XCTAssertEqual(request.headerFields, [:])
    XCTAssertNil(request.body)

    request.method = .post
    XCTAssertEqual(request.method, .post)

    request.scheme = "abc"
    XCTAssertEqual(request.scheme, "abc")

    request.authority = "example.co.uk"
    XCTAssertEqual(request.authority, "example.co.uk")

    request.path = "example/another"
    XCTAssertEqual(request.path, "/example/another")

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
    let request1 = HTTPRequestData(
      authority: "example.com"
    )
    XCTAssertEqual(request1.identifier, "000001")
    let request2 = HTTPRequestData(
      authority: "example.com"
    )
    XCTAssertEqual(request2.identifier, "000002")
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

  func test__url_request() throws {
    struct Body: Encodable {
      let message: String
    }
    let body = Body(message: "Hello world")
    let http = try HTTPRequestData(
      method: .post,
      authority: "example.com",
      path: "example",
      body: JSONBody(body)
    )
    let request = try XCTUnwrap(URLRequest(http: http))
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(request.url, URL(static: "https://example.com/example"))
    XCTAssertEqual(request.httpBody, try JSONEncoder().encode(body))
    XCTAssertEqual(request.allHTTPHeaderFields, [
      "Content-Type": "application/json; charset=utf-8"
    ])
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
