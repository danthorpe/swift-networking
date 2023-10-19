import Dependencies
import Foundation
import ShortID
import Tagged
import XCTest

@testable import Networking

final class ProgressTrackerTests: XCTestCase {
  
  func test__basics() async {
    let tracker = ProgressTracker()
    
    await tracker.set(id: "Hello", bytesReceived: BytesReceived(received: 10, expected: 100))
    var fraction = await tracker.fractionCompleted()
    XCTAssertEqual(fraction, 0.1, accuracy: 0.00001)
    
    await tracker.set(id: "Hello", bytesReceived: BytesReceived(received: 85, expected: 100))
    fraction = await tracker.fractionCompleted()
    XCTAssertEqual(fraction, 0.85, accuracy: 0.00001)
    
    await tracker.set(id: "World", bytesReceived: BytesReceived(received: 20, expected: 100))
    fraction = await tracker.fractionCompleted()
    XCTAssertEqual(fraction, 0.525, accuracy: 0.00001)
    
    await tracker.set(id: "Hello", bytesReceived: BytesReceived(received: 100, expected: 100))
    fraction = await tracker.fractionCompleted()
    XCTAssertEqual(fraction, 0.60, accuracy: 0.00001)
    
    await tracker.set(id: "World", bytesReceived: BytesReceived(received: 40, expected: 100))
    fraction = await tracker.fractionCompleted()
    XCTAssertEqual(fraction, 0.70, accuracy: 0.00001)
    
    await tracker.remove(id: "Hello")
    fraction = await tracker.fractionCompleted()
    XCTAssertEqual(fraction, 0.40, accuracy: 0.00001)
    
    await tracker.set(id: "World", bytesReceived: BytesReceived(received: 80, expected: 100))
    fraction = await tracker.fractionCompleted()
    XCTAssertEqual(fraction, 0.80, accuracy: 0.00001)
    
    await tracker.remove(id: "World")
    fraction = await tracker.fractionCompleted()
    XCTAssertEqual(fraction, 0.0, accuracy: 0.00001)
  }
}
