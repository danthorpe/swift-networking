import struct os.OSAllocatedUnfairLock
import struct os.os_unfair_lock
import struct os.os_unfair_lock_t
import func os.os_unfair_lock_lock
import func os.os_unfair_lock_unlock
import func os.os_unfair_lock_trylock

@available(macOS, deprecated: 15.0, message: "use Mutex from Synchronization module included with Swift 6")
@available(iOS, deprecated: 18.0, message: "use Mutex from Synchronization module included with Swift 6")
@available(tvOS, deprecated: 18.0, message: "use Mutex from Synchronization module included with Swift 6")
@available(watchOS, deprecated: 11.0, message: "use Mutex from Synchronization module included with Swift 6")
@available(visionOS, deprecated: 2.0, message: "use Mutex from Synchronization module included with Swift 6")
package struct Mutex<Value: ~Copyable>: ~Copyable, Sendable {
  final class Storage: @unchecked Sendable {
    private let _lock: os_unfair_lock_t
    var value: Value

    init(initialValue: consuming Value) {
      _lock = .allocate(capacity: 1)
      _lock.initialize(to: os_unfair_lock())
      value = initialValue
    }
    deinit {
      _lock.deinitialize(count: 1)
      _lock.deallocate()
    }
    func lock() {
      os_unfair_lock_lock(_lock)
    }
    func unlock() {
      os_unfair_lock_unlock(_lock)
    }
    func tryLock() -> Bool {
      os_unfair_lock_trylock(_lock)
    }
  }
  let storage: Storage
}

package extension Mutex {
  init(_ initialValue: consuming sending Value) {
    storage = Storage(initialValue: initialValue)
  }

  @discardableResult
  borrowing func withLock<Result, E: Error>(
    _ body: (inout sending Value) throws(E) -> sending Result
  ) throws(E) -> sending Result {
    storage.lock()
    defer { storage.unlock() }
    return try body(&storage.value)
  }

  @discardableResult
  borrowing func withLockIfAvailable<Result, E: Error>(
    _ body: (inout sending Value) throws(E) -> sending Result
  ) throws(E) -> sending Result? {
    guard storage.tryLock() else { return nil }
    defer { storage.unlock() }
    return try body(&storage.value)
  }
}
