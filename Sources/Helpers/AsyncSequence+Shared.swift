import Foundation

extension AsyncSequence where Self: Sendable, Self.Element: Sendable {
  public func shared() -> SharedAsyncSequence<Self> {
    SharedAsyncSequence(self)
  }
}

public final class SharedAsyncSequence<Base: AsyncSequence>: Sendable where Base: Sendable, Base.Element: Sendable {
  fileprivate typealias Stream = AsyncThrowingStream<Base.Element, Error>
  private typealias Continuations = [String: Stream.Continuation]
  private typealias Subscription = Task<Void, Never>

  private struct Storage: Sendable {
    var continuations: Continuations = [:]
    var subscription: Subscription?
  }

  private let base: Base
  private let storage = Mutex(Storage())

  init(_ base: Base) {
    self.base = base
  }

  private func remove(id key: String) {
    storage.withLock { $0.continuations.removeValue(forKey: key) }
  }

  private func add(id key: String, continuation: Stream.Continuation) {
    storage.withLock {
      $0.continuations[key] = continuation
      if $0.subscription == nil {
        $0.subscription = createSubscription()
      }
    }
  }

  private func createSubscription() -> Subscription {
    Subscription {
      func forEachContinuation(perform operation: (Stream.Continuation) -> Void) {
        storage.withLock { $0.continuations.values }.forEach(operation)
      }
      func isCancelled() -> Bool {
        guard Task.isCancelled else { return false }
        forEachContinuation { $0.finish(throwing: CancellationError()) }
        return true
      }
      guard !isCancelled() else { return }
      do {
        for try await element in base {
          forEachContinuation { $0.yield(element) }
          try Task.checkCancellation()
        }
        if !isCancelled() {
          forEachContinuation { $0.finish() }
        }
      } catch {
        forEachContinuation { $0.finish(throwing: error) }
      }
    }
  }
}

extension SharedAsyncSequence: AsyncSequence {
  public typealias AsyncIterator = AsyncThrowingStream<Base.Element, Error>.Iterator
  public typealias Element = Base.Element

  public func makeAsyncIterator() -> AsyncThrowingStream<Base.Element, Error>.Iterator {
    let id = UUID().uuidString
    let (stream, continuation) = Stream.makeStream()
    continuation.onTermination = { [weak self] reason in
      guard case .cancelled = reason else { return }
      self?.remove(id: id)
    }
    add(id: id, continuation: continuation)
    return stream.makeAsyncIterator()
  }
}
