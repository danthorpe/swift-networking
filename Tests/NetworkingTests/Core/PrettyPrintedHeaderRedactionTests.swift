import Foundation
import HTTPTypes
import Testing

@testable import Networking

struct PrettyPrintedHeaderRedactionTests {

  @Test func authorizationRedactedWithNoConfiguration() {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    request.headerFields[.authorization] = "Bearer ya29.a0-secret"
    let out = request.prettyPrintedHeaders
    #expect(!out.contains("ya29.a0-secret"))
    #expect(out.contains("Authorization: <redacted>"))
  }

  @Test func nonSensitiveHeadersStillPrintTheirValues() {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    request.headerFields[.contentType] = "application/json"
    request.headerFields[.authorization] = "Bearer secret"
    let out = request.prettyPrintedHeaders
    #expect(out.contains("Content-Type: application/json"))
    #expect(!out.contains("secret"))
  }

  @Test func widenedSetRedactsAdditionalHeaders() {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    request.headerFields[.init("X-Api-Key")!] = "key-secret"
    request.redactedHeaderFields = [.authorization, .init("X-Api-Key")!]
    let out = request.prettyPrintedHeaders
    #expect(!out.contains("key-secret"))
    #expect(out.contains("X-Api-Key: <redacted>"))
  }

  @Test func responseHeadersRedactedUsingRequestFields() throws {
    let url = URL(string: "https://example.com")!
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    let response = try HTTPResponseData(
      request: request,
      data: Data(),
      urlResponse: HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: "HTTP/1.1",
        headerFields: ["Set-Cookie": "session=secret", "Content-Type": "application/json"]
      )
    )
    let out = response.prettyPrintedHeaders
    #expect(!out.contains("session=secret"))
    #expect(out.contains("Set-Cookie: <redacted>"))
    #expect(out.contains("Content-Type: application/json"))
  }
}
