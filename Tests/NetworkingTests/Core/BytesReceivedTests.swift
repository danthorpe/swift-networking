import Dependencies
import Foundation
import ShortID
import Tagged
import XCTest

@testable import Networking

final class BytesReceivedTests: XCTestCase {
  func test__init_data() throws {
    let data = try XCTUnwrap("Hello World".data(using: .utf8))
    let bytes = BytesReceived(data: data)
    XCTAssertEqual(bytes.received, 11)
    XCTAssertEqual(bytes.expected, 11)
  }
  
  func test__receive_bytes() {
    var bytes = BytesReceived(expected: 256)
    bytes.receiveBytes(count: 64)
    bytes.receiveBytes(count: 64)
    XCTAssertEqual(bytes.received, 128)
    XCTAssertEqual(bytes.expected, 256)
  }
  
  func test__add() {
    let lhs = BytesReceived(received: 10, expected: 10)
    let rhs = BytesReceived(received: 20, expected: 20)
    XCTAssertEqual(lhs + rhs, BytesReceived(received: 30, expected: 30))
  }
  
  func test__fraction_completed() {
    var bytes = BytesReceived(received: 10, expected: 100)
    XCTAssertEqual(bytes.fractionCompleted, 0.1, accuracy: 0.00001)
    bytes.receiveBytes(count: 50)
    XCTAssertEqual(bytes.fractionCompleted, 0.6, accuracy: 0.00001)
  }
  
  func test__with_expected_bytes_from_request__default() throws {
    let request = HTTPRequestData(id: .init("1"), authority: "example.com")
    let data = try XCTUnwrap("Hello World".data(using: .utf8))
    let bytes = BytesReceived(data: data).withExpectedContentLength(from: request)
    XCTAssertEqual(bytes.received, 11)
    XCTAssertEqual(bytes.expected, 11)
  }
  
  func test__with_expected_bytes_from_request() throws {
    var request = HTTPRequestData(id: .init("1"), authority: "example.com")
    request.expectedContentLength = 100
    let data = try XCTUnwrap("Hello World".data(using: .utf8))
    let bytes = BytesReceived(data: data).withExpectedContentLength(from: request)
    XCTAssertEqual(bytes.received, 11)
    XCTAssertEqual(bytes.expected, 100)
  }
}
