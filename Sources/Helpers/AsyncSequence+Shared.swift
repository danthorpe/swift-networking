import Foundation

extension AsyncSequence where Self: Sendable {

  public func shared() -> SharedAsyncSequence<Self> {
    SharedAsyncSequence(self)
  }
}

public struct SharedAsyncSequence<Base: AsyncSequence> {

  fileprivate typealias Stream = AsyncThrowingStream<Base.Element, Error>

  fileprivate actor Coordinator {
    var base: Base
    var continuations: [String: Stream.Continuation] = [:]
    var subscription: Task<Void, Never>?

    init(_ base: Base) {
      self.base = base
    }

    deinit {
      self.subscription?.cancel()
    }

    func add(id: String, continuation: Stream.Continuation) {
      self.continuations[id] = continuation
      self.subscribe()
    }

    func remove(id: String) {
      continuations.removeValue(forKey: id)
    }

    func subscribe() {
      guard subscription == nil else { return }
      subscription = Task {
        func isCancelled() -> Bool {
          if Task.isCancelled {
            continuations.values.forEach {
              $0.finish(throwing: CancellationError())
            }
            return true
          }
          return false
        }

        guard false == isCancelled() else { return }

        do {
          for try await value in base {
            continuations.values.forEach { $0.yield(value) }
            try Task.checkCancellation()
          }
          if false == isCancelled() {
            continuations.values.forEach { $0.finish() }
          }
        } catch {
          continuations.values.forEach { $0.finish(throwing: error) }
        }
      }
    }

    nonisolated func makeAsyncIterator() -> Stream.AsyncIterator {
      let id = UUID().uuidString
      let sequence = Stream { continuation in
        continuation.onTermination = { @Sendable _ in
          Task {
            await self.remove(id: id)
          }
        }
        Task {
          await self.add(id: id, continuation: continuation)
        }
      }
      return sequence.makeAsyncIterator()
    }
  }

  private var base: Base
  fileprivate var coordinator: Coordinator

  init(_ base: Base) {
    self.base = base
    self.coordinator = Coordinator(base)
  }
}

extension SharedAsyncSequence: Sendable where Base: Sendable {}

extension SharedAsyncSequence: AsyncSequence {
  public typealias AsyncIterator = AsyncThrowingStream<Base.Element, Error>.Iterator
  public typealias Element = Base.Element

  public func makeAsyncIterator() -> AsyncThrowingStream<Base.Element, Error>.Iterator {
    coordinator.makeAsyncIterator()
  }
}
