import Foundation

public extension UUID {
    @TaskLocal
    static var generator: () -> UUID = UUID.init
}

extension HTTPRequest {
    public actor SequenceNumber {

        @TaskLocal
        public static var next: (Int) -> Int = { $0 + 1 }

        private var value: Int

        init(from value: Int) {
            self.value = value
        }

        func next() -> Int {
            value = SequenceNumber.next(value)
            return value
        }
    }
}

public struct GenerateRequestIdentifiers<Upstream: HTTPLoadable>: HTTPLoadable {
    public let upstream: Upstream

    private let sequence = HTTPRequest.SequenceNumber(from: 0)

    /// This is deliberately not exposed, to prevent framework
    /// consumers from accidentally breaking it.
    init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
        var copy = request
        copy.id = .init(rawValue: UUID.generator())
        copy.number = await sequence.next()
        return try await upstream.load(copy)
    }
}
