@testable import Helpers
import Synchronization
import TestSupport
import Testing

struct MutexTests {

  @Test func withLockReturnsValue() {
    let mutex = Mutex("Hello")
    #expect(mutex.withLock { $0 + " World" } == "Hello World")
  }

  @Test func withLockThrowsError() {
    let mutex = Mutex("Hello")
    #expect(throws: CancellationError.self) {
      try mutex.withLock { _ in throw CancellationError() }
    }
  }

  @Test func withLockIfAvailableReturnsValue() {
    let mutex = Mutex("Hello")
    mutex.unsafeLock()
    #expect(mutex.withLockIfAvailable { $0 + " World" } == nil)
    mutex.unsafeUnlock()
    #expect(mutex.withLockIfAvailable { $0 + " World" } == "Hello World")
  }

  @Test func withLockIfAvailableThrowsError() {
    let mutex = Mutex("Hello")
    #expect(throws: CancellationError.self) {
      try mutex.withLockIfAvailable { _ in throw CancellationError() }
    }
  }

  @Test func withNoncopyableType() {
    struct Payload: ~Copyable {
      var message: String
    }
    let mutex = Mutex(Payload(message: "Hello"))
    mutex.withLock { payload in
      var copy = payload
      copy.message = "Hello World"
      payload = copy
    }
    #expect(mutex.withLock { $0.message } == "Hello World")
  }

  @Test(
    arguments: [
      1000,
      10_000,
      100_000,
      1_000_000,
      10_000_000
    ]
  ) func testMutalAccess(count: Int) async {
    let control = await measureConcurrentOperations(count: count) { _ in }
    let backport = Mutex<[Int: Int]>([:])
    let backportMeasurement = await measureConcurrentOperations(count: count) { index in
      backport.withLock { $0[index] = index }
    }
    #expect(backport.withLock { $0.keys.count } == count)

    if #available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *) {
      let mutex = Synchronization.Mutex<[Int: Int]>([:])
      let mutexMeasurement = await measureConcurrentOperations(count: count) { index in
        mutex.withLock { $0[index] = index }
      }
      print(
        "\(count) -> Control: \(String(format: "%.4f", control)), Swift 6 Mutex: \(String(format: "%.4f", mutexMeasurement)), Mutex Backport: \(String(format: "%.4f", backportMeasurement))"
      )
    } else {
      print(
        "\(count) -> Control: \(String(format: "%.4f", control)), Mutex Backport: \(String(format: "%.4f", backportMeasurement))"
      )
    }
  }
}

extension Helpers.Mutex {
  func unsafeLock() { storage.lock() }
  func unsafeUnlock() { storage.unlock() }
}
