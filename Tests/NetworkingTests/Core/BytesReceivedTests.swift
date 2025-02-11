import Dependencies
import Foundation
import Numerics
import ShortID
import Tagged
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct BytesReceivedTests {

  @Test func test__init_data() throws {
    let data = try #require("Hello World".data(using: .utf8))
    let bytes = BytesReceived(data: data)
    #expect(bytes.received == 11)
    #expect(bytes.expected == 11)
  }

  @Test func test__receive_bytes() {
    var bytes = BytesReceived(expected: 256)
    bytes.receiveBytes(count: 64)
    bytes.receiveBytes(count: 64)
    #expect(bytes.received == 128)
    #expect(bytes.expected == 256)
  }

  @Test func test__add() {
    let lhs = BytesReceived(received: 10, expected: 10)
    let rhs = BytesReceived(received: 20, expected: 20)
    #expect(lhs + rhs == BytesReceived(received: 30, expected: 30))
  }

  @Test func test__fraction_completed() {
    var bytes = BytesReceived(received: 10, expected: 100)
    #expect(bytes.fractionCompleted.isApproximatelyEqual(to: 0.1))
    bytes.receiveBytes(count: 50)
    #expect(bytes.fractionCompleted.isApproximatelyEqual(to: 0.6))
  }

  @Test func test__with_expected_bytes_from_request__default() throws {
    let data = try #require("Hello World".data(using: .utf8))
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    let bytes = BytesReceived(data: data).withExpectedContentLength(from: request)
    #expect(bytes.received == 11)
    #expect(bytes.expected == 11)
  }

  func test__with_expected_bytes_from_request() throws {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    request.expectedContentLength = 100
    let data = try #require("Hello World".data(using: .utf8))
    let bytes = BytesReceived(data: data).withExpectedContentLength(from: request)
    #expect(bytes.received == 11)
    #expect(bytes.expected == 100)
  }
}
