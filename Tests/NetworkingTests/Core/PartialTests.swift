import Dependencies
import Foundation
import ShortID
import Tagged
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct PartialTests {

  @Test func test__value() {
    #expect(Partial<String, Double>.progress(0.1).value == nil)
    #expect(Partial<String, Double>.value("Hello", 1.0).value == "Hello")
  }

  @Test func test__progress() {
    #expect(Partial<String, Double>.progress(0.1).progress.isApproximatelyEqual(to: 0.1))
    #expect(Partial<String, Double>.value("Hello", 1.0).progress.isApproximatelyEqual(to: 1.0))
  }

  @Test func test__on_value() {
    var didPerformBlock: String?
    var partial: Partial<String, Double> = .value("Hello", 1.0)
    var onValue = partial.onValue { didPerformBlock = $0 }
    #expect(didPerformBlock == "Hello")
    #expect(partial == onValue)

    didPerformBlock = nil
    partial = .progress(0.1)
    onValue = partial.onValue { didPerformBlock = $0 }
    #expect(didPerformBlock == nil)
    #expect(partial == onValue)
  }

  @Test func test__map_value() {
    var partial: Partial<String, Double> = .value("Hello", 1.0)
    var mapValue = partial.mapValue { $0.count }
    #expect(mapValue == .value(5, 1.0))
    #expect(partial == .value("Hello", 1.0))

    partial = .progress(0.1)
    mapValue = partial.mapValue { $0.count }
    #expect(mapValue == .progress(0.1))
    #expect(partial == .progress(0.1))
  }

  @Test func test__map_progress() {
    var partial: Partial<String, Double> = .value("Hello", 1.0)
    var mapProgress = partial.mapProgress {
      BytesReceived(received: Int64(100 * $0), expected: 100)
    }
    #expect(mapProgress == .value("Hello", BytesReceived(received: 100, expected: 100)))
    #expect(partial == .value("Hello", 1.0))

    partial = .progress(0.1)
    mapProgress = partial.mapProgress {
      BytesReceived(received: Int64(100 * $0), expected: 100)
    }
    #expect(mapProgress == .progress(BytesReceived(received: 10, expected: 100)))
    #expect(partial == .progress(0.1))
  }
}
