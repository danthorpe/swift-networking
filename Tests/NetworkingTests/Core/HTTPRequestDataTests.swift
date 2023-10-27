import CustomDump
import Dependencies
import ShortID
import Tagged
import XCTest

@testable import Networking

final class HTTPRequestDataTests: XCTestCase {

  var request: HTTPRequestData! {
    didSet {
      if let request {
        urlRequest = URLRequest(http: request)
      }
    }
  }
  var urlRequest: URLRequest!

  override func tearDown() {
    request = nil
    urlRequest = nil
    super.tearDown()
  }

  override func invokeTest() {
    withDependencies {
      $0.shortID = .incrementing
    } operation: {
      super.invokeTest()
    }
  }

  func check(url: StaticString, file: StaticString = #file, line: UInt = #line) {
    XCTAssertNoDifference(urlRequest.url, URL(static: url), file: file, line: line)
  }

  func test__defaults() throws {
    request = HTTPRequestData()
    XCTAssertNoDifference(request.method, .get)
    XCTAssertNoDifference(urlRequest.httpMethod, "GET")
    XCTAssertNoDifference(request.scheme, "https")
    XCTAssertNoDifference(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertNoDifference(request.path, "/")
    XCTAssertNil(request.queryItems)
    check(url: "https://example.com/")
    XCTAssertNoDifference(request.headerFields, [:])
    XCTAssertNil(request.body)
  }

  func test__set_method() throws {
    request = HTTPRequestData(method: .post)
    XCTAssertNoDifference(request.method, .post)
    XCTAssertNoDifference(urlRequest.httpMethod, "POST")

    request.method = .delete
    XCTAssertNoDifference(request.method, .delete)
    XCTAssertNoDifference(urlRequest.httpMethod, "DELETE")
  }

  func test__set_scheme() throws {
    request = HTTPRequestData(scheme: "http")
    XCTAssertNoDifference(request.scheme, "http")
    check(url: "http://example.com/")

    request.scheme = "myapp"
    XCTAssertNoDifference(request.scheme, "myapp")
    check(url: "myapp://example.com/")
  }

  func test__set_authority() throws {
    request = HTTPRequestData(authority: "hello.com")
    XCTAssertNoDifference(request.authority, "hello.com")
    XCTAssertNil(request.port)
    check(url: "https://hello.com/")

    request = HTTPRequestData(authority: "hello.com:1234")
    XCTAssertNoDifference(request.authority, "hello.com:1234")
    XCTAssertNoDifference(request.port, 1234)
    check(url: "https://hello.com:1234/")

    request.authority = "goodbye.com"
    XCTAssertNoDifference(request.authority, "goodbye.com")
    XCTAssertNil(request.port)
    check(url: "https://goodbye.com/")

    request.authority = "goodbye.com:1234"
    XCTAssertNoDifference(request.authority, "goodbye.com:1234")
    XCTAssertNoDifference(request.port, 1234)
    check(url: "https://goodbye.com:1234/")
  }

  func test__set_path() throws {
    request = HTTPRequestData(path: "example")
    XCTAssertNoDifference(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertNoDifference(request.path, "/example")
    XCTAssertNil(request.queryItems)
    check(url: "https://example.com/example")

    request.path = "another-example"
    XCTAssertNoDifference(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertNoDifference(request.path, "/another-example")
    XCTAssertNil(request.queryItems)
    check(url: "https://example.com/another-example")

    request.path = "example?query=test"
    XCTAssertNoDifference(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertNoDifference(request.path, "/example?query=test")
    XCTAssertNoDifference(request.queryItems, [URLQueryItem(name: "query", value: "test")])
    check(url: "https://example.com/example?query=test")

    request.path = "/"
    XCTAssertNoDifference(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertNoDifference(request.path, "/?query=test")
    XCTAssertNoDifference(request.queryItems, [URLQueryItem(name: "query", value: "test")])
    check(url: "https://example.com/?query=test")
  }

  func test__set_query_items() throws {
    request = HTTPRequestData(path: "example?query=test")
    XCTAssertNoDifference(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertNoDifference(request.path, "/example?query=test")
    XCTAssertNoDifference(request.queryItems, [URLQueryItem(name: "query", value: "test")])
    check(url: "https://example.com/example?query=test")

    request.anotherQuery = "hello"
    XCTAssertNoDifference(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertNoDifference(request.path, "/example?anotherQuery=hello&query=test")
    XCTAssertNoDifference(request.queryItems, [
      URLQueryItem(name: "anotherQuery", value: "hello"),
      URLQueryItem(name: "query", value: "test"),
    ])
    check(url: "https://example.com/example?anotherQuery=hello&query=test")

    request.queryItems = nil
    XCTAssertNoDifference(request.authority, "example.com")
    XCTAssertNil(request.port)
    XCTAssertNoDifference(request.path, "/example")
    XCTAssertNil(request.queryItems)
    check(url: "https://example.com/example")
  }

  func test___standard_percent_encoding() throws {
    // Check that any percent encoded path items retain their percent encoding
    request = HTTPRequestData(path: "example?message=hello%20world")
    XCTAssertNoDifference(request.path, "/example?message=hello%20world")
    check(url: "https://example.com/example?message=hello%20world")

    // Mutate the request, by adding another query item
    // Note - that this is not percent encoded, as we don't expect/assume framework consumers to perform the
    // percent encoding
    request.sender = "Blob Sr."
    XCTAssertNoDifference(request.path, "/example?message=hello%20world&sender=Blob%20Sr.")
    check(url: "https://example.com/example?message=hello%20world&sender=Blob%20Sr.")

    // Mutate the request to a whole URL, with percent encoding
    request.url = URL(static: "https://example.com/example?message=hello%20world")
    XCTAssertNoDifference(request.path, "/example?message=hello%20world")
    check(url: "https://example.com/example?message=hello%20world")
  }

  func test___custom_percent_encoding() throws {
    // Check that any percent encoded path items retain their percent encoding
    request = HTTPRequestData(path: "example?message=hello+world&sender=blob@example.com")
    request.queryItemsAllowedCharacters = .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "@+ "))
    XCTAssertNoDifference(request.path, "/example?message=hello%2Bworld&sender=blob%40example.com")
    check(url: "https://example.com/example?message=hello%2Bworld&sender=blob%40example.com")

    // Mutate the request, by settings a query item
    // Note - that this is not percent encoded, as we don't expect/assume framework consumers to perform the
    // percent encoding
    request.message = "goodbye+world"
    XCTAssertNoDifference(request.path, "/example?message=goodbye%2Bworld&sender=blob%40example.com")
    check(url: "https://example.com/example?message=goodbye%2Bworld&sender=blob%40example.com")
  }

  func test__set_url() throws {
    request = HTTPRequestData()
    check(url: "https://example.com/")

    request.url = URL(static: "http://other.com:1234/some-path?message=Hello+World")
    XCTAssertNoDifference(request.scheme, "http")
    XCTAssertNoDifference(request.authority, "other.com:1234")
    XCTAssertNoDifference(request.port, 1234)
    XCTAssertNoDifference(request.path, "/some-path?message=Hello+World")
    XCTAssertNoDifference(request.queryItems, [URLQueryItem(name: "message", value: "Hello+World")])
    XCTAssertNoDifference(request.message, "Hello+World")
    check(url: "http://other.com:1234/some-path?message=Hello+World")
  }

  func test__basics() {
    request = HTTPRequestData(
      method: .get,
      scheme: "https",
      authority: "example.com",
      path: "example",
      headerFields: [:],
      body: nil
    )

    XCTAssertNoDifference(request.method, .get)
    XCTAssertNoDifference(request.scheme, "https")
    XCTAssertNoDifference(request.authority, "example.com")
    XCTAssertNoDifference(request.path, "/example")
    XCTAssertNoDifference(request.headerFields, [:])
    XCTAssertNil(request.body)

    request.method = .post
    XCTAssertNoDifference(request.method, .post)

    request.scheme = "abc"
    XCTAssertNoDifference(request.scheme, "abc")

    request.authority = "example.co.uk"
    XCTAssertNoDifference(request.authority, "example.co.uk")

    request.path = "example/another"
    XCTAssertNoDifference(request.path, "/example/another")

    request.headerFields = [
      .contentType: "application/json",
      .accept: "application/json",
      .cacheControl: "no-cache",
    ]
    XCTAssertNoDifference(
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
    XCTAssertNoDifference(request1.identifier, "000001")
    let request2 = HTTPRequestData(
      authority: "example.com"
    )
    XCTAssertNoDifference(request2.identifier, "000002")
  }

  func test__options() {
    var request1 = HTTPRequestData(
      id: .init("some id"),
      authority: "example.com"
    )

    XCTAssertNoDifference(request1.testOption, "Hello World")
    request1.testOption = "Goodbye"
    XCTAssertNoDifference(request1.testOption, "Goodbye")

    var request2 = HTTPRequestData(
      id: .init("some id"),
      authority: "example.com"
    )

    // By default request options are not considered when
    // evaluating equality
    XCTAssertNoDifference(request1, request2)

    // Request options can override this behaviour, and signal that
    // they should be considered for equality
    request2.testEqualOption = "Goodbye"
    XCTAssertNotEqual(request1, request2)

    request1.testEqualOption = "Hello Again"
    XCTAssertNotEqual(request1, request2)

    request1.testEqualOption = "Goodbye"
    XCTAssertNoDifference(request1, request2)
  }

  func test__description() throws {
    request = HTTPRequestData(
      id: .init("some id"),
      authority: "example.com"
    )
    try XCTAssertNoDifference(XCTUnwrap(request).debugDescription, "[0:some id] (GET) https://example.com/")

    request.scheme = "abc"
    request.method = .post
    request.path = "/hello"
    try XCTAssertNoDifference(XCTUnwrap(request).debugDescription, "[0:some id] (POST) abc://example.com/hello")
  }

  func test__foundation_url_request_with_path() throws {
    request = HTTPRequestData(
      id: .init("some id"),
      method: .get,
      scheme: "https",
      authority: "example.com",
      path: "example",
      headerFields: [:],
      body: nil
    )
    check(url: "https://example.com/example")
  }

  func test__foundation_url_request_minimum_arguments() throws {
    request = HTTPRequestData(
      authority: "example.com"
    )
    check(url: "https://example.com/")
  }

  func test__url_request() throws {
    struct Body: Encodable {
      let message: String
    }
    let body = Body(message: "Hello world")
    request = try HTTPRequestData(
      method: .post,
      authority: "example.com",
      path: "example",
      body: JSONBody(body)
    )
    XCTAssertNoDifference(urlRequest.httpMethod, "POST")
    XCTAssertNoDifference(urlRequest.httpBody, try JSONEncoder().encode(body))
    XCTAssertNoDifference(urlRequest.allHTTPHeaderFields, [
      "Content-Type": "application/json; charset=utf-8"
    ])
    check(url: "https://example.com/example")
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
