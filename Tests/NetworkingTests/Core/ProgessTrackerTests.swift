import Dependencies
import Foundation
import Numerics
import ShortID
import Tagged
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct ProgressTrackerTests {

  @Test func test__basics() async {
    let tracker = ProgressTracker()

    await tracker.set(id: "Hello", bytesReceived: BytesReceived(received: 10, expected: 100))
    var fraction = await tracker.fractionCompleted()
    #expect(fraction.isApproximatelyEqual(to: 0.1))

    await tracker.set(id: "Hello", bytesReceived: BytesReceived(received: 85, expected: 100))
    fraction = await tracker.fractionCompleted()
    #expect(fraction.isApproximatelyEqual(to: 0.85))

    await tracker.set(id: "World", bytesReceived: BytesReceived(received: 20, expected: 100))
    fraction = await tracker.fractionCompleted()
    #expect(fraction.isApproximatelyEqual(to: 0.525))

    await tracker.set(id: "Hello", bytesReceived: BytesReceived(received: 100, expected: 100))
    fraction = await tracker.fractionCompleted()
    #expect(fraction.isApproximatelyEqual(to: 0.60))

    await tracker.set(id: "World", bytesReceived: BytesReceived(received: 40, expected: 100))
    fraction = await tracker.fractionCompleted()
    #expect(fraction.isApproximatelyEqual(to: 0.70))

    await tracker.remove(id: "Hello")
    fraction = await tracker.fractionCompleted()
    #expect(fraction.isApproximatelyEqual(to: 0.40))

    await tracker.set(id: "World", bytesReceived: BytesReceived(received: 80, expected: 100))
    fraction = await tracker.fractionCompleted()
    #expect(fraction.isApproximatelyEqual(to: 0.80))

    await tracker.remove(id: "World")
    fraction = await tracker.fractionCompleted()
    #expect(fraction.isApproximatelyEqual(to: .zero))
  }
}
