import Foundation
import Testing

@testable import Helpers

struct DataPrettyPrintedTests {
  private func data(_ s: String) -> Data { Data(s.utf8) }

  @Test func emptyDataUnchanged() {
    #expect(Data().prettyPrintedData(redacting: ["a"]) == "Empty data")
  }

  @Test func emptyKeySetIsVerbatim() {
    let body = data(#"{"access_token":"secret"}"#)
    #expect(body.prettyPrintedData() == #"{"access_token":"secret"}"#)
  }

  @Test func jsonTopLevelKeyRedacted() {
    let body = data(#"{"access_token":"secret","expires_in":3599}"#)
    let out = body.prettyPrintedData(redacting: ["access_token"])
    #expect(out.contains("<redacted>"))
    #expect(!out.contains("secret"))
    #expect(out.contains("3599"))          // non-secret field preserved
    #expect(out.contains("access_token"))  // key preserved
  }

  @Test func jsonNestedAndInArrayRedacted() {
    let body = data(#"{"outer":{"refresh_token":"r"},"list":[{"code":"c"}]}"#)
    let out = body.prettyPrintedData(redacting: ["refresh_token", "code"])
    #expect(!out.contains("\"r\""))
    #expect(!out.contains("\"c\""))
    #expect(out.contains("<redacted>"))
  }

  @Test func jsonNonStringValueRedacted() {
    let body = data(#"{"secret_number":12345}"#)
    let out = body.prettyPrintedData(redacting: ["secret_number"])
    #expect(!out.contains("12345"))
    #expect(out.contains("<redacted>"))
  }

  @Test func formUrlencodedRedacted() {
    let body = data("grant_type=refresh_token&refresh_token=1//03z&client_id=abc")
    let out = body.prettyPrintedData(redacting: ["refresh_token"])
    #expect(out == "grant_type=refresh_token&refresh_token=<redacted>&client_id=abc")
  }

  @Test func keyNotInSetLeftIntact() {
    let body = data("grant_type=refresh_token&refresh_token=1//03z")
    let out = body.prettyPrintedData(redacting: ["client_secret"])
    #expect(out.contains("1//03z"))
  }

  @Test func nonParseableBytesVerbatim() {
    let body = data("just a plain log line, no structure")
    #expect(body.prettyPrintedData(redacting: ["access_token"]) == "just a plain log line, no structure")
  }

  // MARK: - Content type & size

  @Test func binaryBodyIsSummarisedNotDecoded() {
    let body = Data(repeating: 0xFF, count: 4096)
    let out = body.prettyPrintedData(contentType: "application/octet-stream")
    #expect(out == "<4096 bytes of application/octet-stream>")
  }

  @Test func imageBodyIsSummarised() {
    let body = Data(repeating: 0x00, count: 10)
    #expect(body.prettyPrintedData(contentType: "image/heic") == "<10 bytes of image/heic>")
  }

  @Test func textualBodyWithParametersIsStillDecoded() {
    let body = data(#"{"a":1}"#)
    #expect(body.prettyPrintedData(contentType: "application/json; charset=utf-8") == #"{"a":1}"#)
  }

  @Test func vendorJSONSuffixIsTextual() {
    let body = data(#"{"a":1}"#)
    #expect(body.prettyPrintedData(contentType: "application/vnd.api+json") == #"{"a":1}"#)
  }

  @Test func unknownContentTypeIsTreatedAsTextual() {
    let body = data("hello")
    #expect(body.prettyPrintedData() == "hello")
  }

  @Test func oversizedTextualBodyIsSummarised() {
    let body = Data(repeating: UInt8(ascii: "a"), count: Data.prettyPrintedByteLimit + 1)
    let out = body.prettyPrintedData(contentType: "text/plain")
    #expect(out == "<8193 bytes, too large to log>")
  }

  @Test func bodyAtTheLimitIsStillDecoded() {
    let body = Data(repeating: UInt8(ascii: "a"), count: Data.prettyPrintedByteLimit)
    #expect(body.prettyPrintedData(contentType: "text/plain").count == Data.prettyPrintedByteLimit)
  }

  @Test func redactionStillAppliesWithinTheLimit() {
    let body = data(#"{"access_token":"secret"}"#)
    let out = body.prettyPrintedData(redacting: ["access_token"], contentType: "application/json")
    #expect(out.contains("<redacted>"))
    #expect(!out.contains("secret"))
  }

  @Test func binaryBodyIsNotDecodedEvenWhenRedacting() {
    let body = Data(repeating: 0xFF, count: 32)
    let out = body.prettyPrintedData(redacting: ["access_token"], contentType: "application/octet-stream")
    #expect(out == "<32 bytes of application/octet-stream>")
  }
}
