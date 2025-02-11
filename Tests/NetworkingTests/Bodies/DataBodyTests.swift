import Dependencies
import Foundation
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct DataBodyTests {

  @Test func emptyDataBody() async throws {
    let body = DataBody(
      data: Data(),
      additionalHeaders: [:]
    )
    #expect(body.isEmpty)
    let encoded = try body.encode()
    #expect(encoded == Data())
  }

  @Test func additionalHeaders() async throws {
    let body = DataBody(
      data: try #require("secret message".data(using: .utf8)),
      additionalHeaders: [.cookie: "secret cookie"]
    )
    let request = try withDependencies {
      $0.shortID = .incrementing
    } operation: {
      try HTTPRequestData(headerFields: [.accept: "application/json"], body: body)
    }
    #expect(
      request.headerFields == [
        .accept: "application/json",
        .cookie: "secret cookie",
      ])
  }
}
