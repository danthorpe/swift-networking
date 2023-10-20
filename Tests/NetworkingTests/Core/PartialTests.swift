import Dependencies
import Foundation
import ShortID
import Tagged
import XCTest

@testable import Networking

final class PartialTests: XCTestCase {

  func test__value() {
    XCTAssertNil(Partial<String, Double>.progress(0.1).value)
    XCTAssertEqual(Partial<String, Double>.value("Hello", 1.0).value, "Hello")
  }

  func test__progress() {
    XCTAssertEqual(Partial<String, Double>.progress(0.1).progress, 0.1)
    XCTAssertEqual(Partial<String, Double>.value("Hello", 1.0).progress, 1.0)
  }

  func test__on_value() {
    var didPerformBlock: String?
    var partial: Partial<String, Double> = .value("Hello", 1.0)
    var onValue = partial.onValue { didPerformBlock = $0 }
    XCTAssertEqual(didPerformBlock, "Hello")
    XCTAssertEqual(partial, onValue)

    didPerformBlock = nil
    partial = .progress(0.1)
    onValue = partial.onValue { didPerformBlock = $0 }
    XCTAssertNil(didPerformBlock)
    XCTAssertEqual(partial, onValue)
  }

  func test__map_value() {
    var partial: Partial<String, Double> = .value("Hello", 1.0)
    var mapValue = partial.mapValue { $0.count }
    XCTAssertEqual(mapValue, .value(5, 1.0))
    XCTAssertEqual(partial, .value("Hello", 1.0))

    partial = .progress(0.1)
    mapValue = partial.mapValue { $0.count }
    XCTAssertEqual(mapValue, .progress(0.1))
    XCTAssertEqual(partial, .progress(0.1))
  }

  func test__map_progress() {
    var partial: Partial<String, Double> = .value("Hello", 1.0)
    var mapProgress = partial.mapProgress {
      BytesReceived(received: Int64(100 * $0), expected: 100)
    }
    XCTAssertEqual(
      mapProgress,
      .value("Hello", BytesReceived(received: 100, expected: 100)))
    XCTAssertEqual(partial, .value("Hello", 1.0))

    partial = .progress(0.1)
    mapProgress = partial.mapProgress {
      BytesReceived(received: Int64(100 * $0), expected: 100)
    }
    XCTAssertEqual(
      mapProgress,
      .progress(BytesReceived(received: 10, expected: 100)))
    XCTAssertEqual(partial, .progress(0.1))
  }
}
