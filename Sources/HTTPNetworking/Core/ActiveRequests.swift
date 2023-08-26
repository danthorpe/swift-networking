import ConcurrencyExtras
import Helpers

public actor ActiveRequests {
    public typealias SharedStream = SharedAsyncSequence<ResponseStream<HTTPResponseData>>
    public struct Key: Hashable {
        public let id: HTTPRequestData.ID
        public let number = RequestSequence.number
    }
    public struct Value {
        public let request: HTTPRequestData
        let stream: SharedStream
    }

    public private(set) var active: [Key: Value] = [:]

    public var count: Int { active.count }

    @discardableResult
    public func add(
        stream: ResponseStream<HTTPResponseData>,
        for request: HTTPRequestData
    ) -> SharedStream {
        let shared = ResponseStream<HTTPResponseData> { continuation in
            Task {
                await stream.redirect(into: continuation, onTermination: { @Sendable in
                    await self.removeStream(for: request)
                })
            }
        }.shared()

        active[Key(id: request.id)] = Value(request: request, stream: shared)
        return shared
    }

    public func removeStream(for request: HTTPRequestData) {
        active[Key(id: request.id)] = nil
    }

    public func waitUntilCountLessThan(_ limit: UInt, countDidChange: @Sendable (Int) async -> Void) async throws {
        var initial = active.count
        while active.count > limit {
            try Task.checkCancellation()
            let latest = active.count
            if initial > latest {
                initial = latest
                await countDidChange(latest)
            }
            await Task.yield()
        }
    }
}
