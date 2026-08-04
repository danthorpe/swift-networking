import Foundation
import Testing

@testable import Networking

struct PrettyPrintedBodyRedactionTests {
  @Test func requestBodyRedactedUsingItsOwnFields() {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    request.body = Data(#"{"access_token":"secret","expires_in":1}"#.utf8)
    request.redactedBodyFields = ["access_token"]
    let out = request.prettyPrintedBody
    #expect(!out.contains("secret"))
    #expect(out.contains("<redacted>"))
    #expect(out.contains("expires_in"))
  }

  @Test func responseBodyRedactedUsingRequestFields() throws {
    let url = URL(string: "https://example.com")!
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    request.redactedBodyFields = ["refresh_token"]
    let response = try HTTPResponseData(
      request: request,
      data: Data(#"{"refresh_token":"r","token_type":"Bearer"}"#.utf8),
      urlResponse: HTTPURLResponse(
        url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)
    )
    let out = response.prettyPrintedBody
    #expect(!out.contains("\"r\""))
    #expect(out.contains("<redacted>"))
    #expect(out.contains("token_type"))
  }
}
