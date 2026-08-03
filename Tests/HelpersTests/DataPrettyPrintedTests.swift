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
}
