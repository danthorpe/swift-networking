import CustomDump
import Dependencies
import Foundation
import ShortID
import Tagged
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct HTTPRequestDataTests: TestableNetwork {  // swiftlint:disable:this type_body_length

  func check(_ request: HTTPRequestData, is url: StaticString, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(URLRequest(http: request)?.url == URL(static: url), sourceLocation: sourceLocation)
  }

  @Test func test__defaults() throws {
    let request = withTestDependencies {
      HTTPRequestData()
    }
    #expect(request.method == .get)
    #expect(URLRequest(http: request)?.httpMethod == "GET")
    #expect(request.scheme == "https")
    #expect(request.authority == "example.com")
    #expect(request.port == nil)
    #expect(request.path == "/")
    #expect(request.queryItems == nil)
    check(request, is: "https://example.com/")
    #expect(request.headerFields == [:])
    #expect(request.body == nil)
  }

  @Test func test__set_method() throws {
    var request = withTestDependencies {
      HTTPRequestData(method: .post)
    }
    #expect(request.method == .post)
    var httpMethod = try #require(URLRequest(http: request)?.httpMethod)
    #expect(httpMethod == "POST")

    request.method = .delete
    #expect(request.method == .delete)
    httpMethod = try #require(URLRequest(http: request)?.httpMethod)
    #expect(httpMethod == "DELETE")
  }

  @Test func test__set_scheme() throws {
    var request = withTestDependencies {
      HTTPRequestData(scheme: "http")
    }
    #expect(request.scheme == "http")
    check(request, is: "http://example.com/")

    request.scheme = "myapp"
    #expect(request.scheme == "myapp")
    check(request, is: "myapp://example.com/")
  }

  @Test func test__set_authority() throws {
    var request = withTestDependencies {
      HTTPRequestData(authority: "hello.com")
    }
    #expect(request.authority == "hello.com")
    #expect(request.port == nil)
    check(request, is: "https://hello.com/")

    request = withTestDependencies {
      HTTPRequestData(authority: "hello.com:1234")
    }
    #expect(request.authority == "hello.com:1234")
    #expect(request.port == 1234)
    check(request, is: "https://hello.com:1234/")

    request.authority = "goodbye.com"
    #expect(request.authority == "goodbye.com")
    #expect(request.port == nil)
    check(request, is: "https://goodbye.com/")

    request.authority = "goodbye.com:1234"
    #expect(request.authority == "goodbye.com:1234")
    #expect(request.port == 1234)
    check(request, is: "https://goodbye.com:1234/")
  }

  @Test func test__set_path() throws {
    var request = withTestDependencies {
      HTTPRequestData(path: "example")
    }
    #expect(request.authority == "example.com")
    #expect(request.port == nil)
    #expect(request.path == "/example")
    #expect(request.queryItems == nil)
    check(request, is: "https://example.com/example")

    request.path = "another-example"
    #expect(request.authority == "example.com")
    #expect(request.port == nil)
    #expect(request.path == "/another-example")
    #expect(request.queryItems == nil)
    check(request, is: "https://example.com/another-example")

    request.path = "example?query=test"
    #expect(request.authority == "example.com")
    #expect(request.port == nil)
    #expect(request.path == "/example?query=test")
    #expect(request.queryItems == [URLQueryItem(name: "query", value: "test")])
    check(request, is: "https://example.com/example?query=test")

    request.path = "/"
    #expect(request.authority == "example.com")
    #expect(request.port == nil)
    #expect(request.path == "/?query=test")
    #expect(request.queryItems == [URLQueryItem(name: "query", value: "test")])
    check(request, is: "https://example.com/?query=test")
  }

  @Test func test__set_query_items() throws {
    var request = withTestDependencies {
      HTTPRequestData(path: "example?query=test")
    }
    #expect(request.authority == "example.com")
    #expect(request.port == nil)
    #expect(request.path == "/example?query=test")
    #expect(request.queryItems == [URLQueryItem(name: "query", value: "test")])
    check(request, is: "https://example.com/example?query=test")

    request.anotherQuery = "hello"
    #expect(request.authority == "example.com")
    #expect(request.port == nil)
    #expect(request.path == "/example?anotherQuery=hello&query=test")
    #expect(
      request.queryItems == [
        URLQueryItem(name: "anotherQuery", value: "hello"),
        URLQueryItem(name: "query", value: "test"),
      ])
    check(request, is: "https://example.com/example?anotherQuery=hello&query=test")

    request.queryItems = nil
    #expect(request.authority == "example.com")
    #expect(request.port == nil)
    #expect(request.path == "/example")
    #expect(request.queryItems == nil)
    check(request, is: "https://example.com/example")
  }

  @Test func test___standard_percent_encoding() throws {
    // Check that any percent encoded path items retain their percent encoding
    var request = withTestDependencies {
      HTTPRequestData(path: "example?message=hello%20world")
    }
    #expect(request.path == "/example?message=hello%20world")
    check(request, is: "https://example.com/example?message=hello%20world")

    // Mutate the request, by adding another query item
    // Note - that this is not percent encoded, as we don't expect/assume framework consumers to perform the
    // percent encoding
    request.sender = "Blob Sr."
    #expect(request.path == "/example?message=hello%20world&sender=Blob%20Sr.")
    check(request, is: "https://example.com/example?message=hello%20world&sender=Blob%20Sr.")

    // Mutate the request to a whole URL, with percent encoding
    request.url = URL(static: "https://example.com/example?message=hello%20world")
    #expect(request.path == "/example?message=hello%20world")
    check(request, is: "https://example.com/example?message=hello%20world")
  }

  @Test func test___custom_percent_encoding() throws {
    // Check that any percent encoded path items retain their percent encoding
    var request = withTestDependencies {
      HTTPRequestData(path: "example?message=hello+world&sender=blob@example.com")
    }
    request.queryItemsAllowedCharacters = .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "@+ "))
    #expect(request.path == "/example?message=hello%2Bworld&sender=blob%40example.com")
    check(request, is: "https://example.com/example?message=hello%2Bworld&sender=blob%40example.com")

    // Mutate the request, by settings a query item
    // Note - that this is not percent encoded, as we don't expect/assume framework consumers to perform the
    // percent encoding
    request.message = "goodbye+world"
    #expect(request.path == "/example?message=goodbye%2Bworld&sender=blob%40example.com")
    check(request, is: "https://example.com/example?message=goodbye%2Bworld&sender=blob%40example.com")
  }

  @Test func test__default_query_encoding() throws {
    var request = withTestDependencies {
      HTTPRequestData(path: "example?message=hello+world")
    }
    request.keywords = "&#"
    #expect(request.path == "/example?keywords=%26%23&message=hello+world")
    check(request, is: "https://example.com/example?keywords=%26%23&message=hello+world")
  }

  @Test func test__set_url() throws {
    var request = withTestDependencies {
      HTTPRequestData()
    }
    check(request, is: "https://example.com/")

    request.url = URL(static: "http://other.com:1234/some-path?message=Hello+World")
    #expect(request.scheme == "http")
    #expect(request.authority == "other.com:1234")
    #expect(request.port == 1234)
    #expect(request.path == "/some-path?message=Hello+World")
    #expect(request.queryItems == [URLQueryItem(name: "message", value: "Hello+World")])
    #expect(request.message == "Hello+World")
    check(request, is: "http://other.com:1234/some-path?message=Hello+World")
  }

  @Test func test__basics() {
    var request = withTestDependencies {
      HTTPRequestData(
        method: .get,
        scheme: "https",
        authority: "example.com",
        path: "example",
        headerFields: [:],
        body: nil
      )
    }

    #expect(request.method == .get)
    #expect(request.scheme == "https")
    #expect(request.authority == "example.com")
    #expect(request.path == "/example")
    #expect(request.headerFields == [:])
    #expect(request.body == nil)

    request.method = .post
    #expect(request.method == .post)

    request.scheme = "abc"
    #expect(request.scheme == "abc")

    request.authority = "example.co.uk"
    #expect(request.authority == "example.co.uk")

    request.path = "example/another"
    #expect(request.path == "/example/another")

    request.headerFields = [
      .contentType: "application/json",
      .accept: "application/json",
      .cacheControl: "no-cache",
    ]
    #expect(
      request.headerFields == [
        .contentType: "application/json",
        .accept: "application/json",
        .cacheControl: "no-cache",
      ])
    #expect(request.body == nil)
  }

  @Test func test__short_id() {
    withTestDependencies {
      let request1 = HTTPRequestData(
        authority: "example.com"
      )
      #expect(request1.identifier == "000001")
      let request2 = HTTPRequestData(
        authority: "example.com"
      )
      #expect(request2.identifier == "000002")
    }
  }

  @Test func test__options() {
    var (request1, request2) = withTestDependencies {
      let request1 = HTTPRequestData(
        id: .init("some id"),
        authority: "example.com"
      )
      let request2 = HTTPRequestData(
        id: .init("some id"),
        authority: "example.com"
      )
      return (request1, request2)
    }

    #expect(request1.testOption == "Hello World")
    request1.testOption = "Goodbye"
    #expect(request1.testOption == "Goodbye")

    // By default request options are not considered when
    // evaluating equality
    #expect(request1 == request2)

    // Request options can override this behaviour, and signal that
    // they should be considered for equality
    request2.testEqualOption = "Goodbye"
    #expect(request1 != request2)

    request1.testEqualOption = "Hello Again"
    #expect(request1 != request2)

    request1.testEqualOption = "Goodbye"
    #expect(request1 == request2)
  }

  @Test func test__description() throws {
    var request = withTestDependencies {
      HTTPRequestData(
        id: .init("some id"),
        authority: "example.com"
      )
    }
    #expect(request.debugDescription == "[0:some id] (GET) https://example.com/")

    request.scheme = "abc"
    request.method = .post
    request.path = "/hello"
    #expect(request.debugDescription == "[0:some id] (POST) abc://example.com/hello")
  }

  @Test func test__foundation_url_request_with_path() throws {
    let request = withTestDependencies {
      HTTPRequestData(
        id: .init("some id"),
        method: .get,
        scheme: "https",
        authority: "example.com",
        path: "example",
        headerFields: [:],
        body: nil
      )
    }
    check(request, is: "https://example.com/example")
  }

  @Test func test__foundation_url_request_minimum_arguments() throws {
    let request = withTestDependencies {
      HTTPRequestData(
        authority: "example.com"
      )
    }
    check(request, is: "https://example.com/")
  }

  @Test func test__url_request() throws {
    struct Body: Encodable {
      let message: String
    }
    let body = Body(message: "Hello world")
    let request = try withTestDependencies {
      try HTTPRequestData(
        method: .post,
        authority: "example.com",
        path: "example",
        body: JSONBody(body)
      )
    }
    let urlRequest = try #require(URLRequest(http: request))
    #expect(urlRequest.httpMethod == "POST")
    let encodedBody = try JSONEncoder().encode(body)
    #expect(urlRequest.httpBody == encodedBody)
    #expect(
      urlRequest.allHTTPHeaderFields == [
        "Content-Type": "application/json; charset=utf-8"
      ])
    check(request, is: "https://example.com/example")
  }
}

private struct TestOption: HTTPRequestDataOption {
  static let defaultOption: String = "Hello World"
}

extension HTTPRequestData {
  fileprivate var testOption: TestOption.Value {
    get { self[option: TestOption.self] }
    set { self[option: TestOption.self] = newValue }
  }
}

private struct TestEqualOption: HTTPRequestDataOption {
  static let defaultOption: String = "Hello World"
  static var includeInEqualityEvaluation: Bool { true }
}

extension HTTPRequestData {
  fileprivate var testEqualOption: TestEqualOption.Value {
    get { self[option: TestEqualOption.self] }
    set { self[option: TestEqualOption.self] = newValue }
  }
}
