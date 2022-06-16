import Foundation
import URLRouting

actor SequenceNumber {
    @TaskLocal
    static var next: (Int) -> Int = { $0 + 1 }

    private var value: Int

    init(from value: Int) {
        self.value = value
    }

    func next() -> Int {
        value = SequenceNumber.next(value)
        return value
    }
}

public struct Numbered<Upstream: NetworkStackable>: NetworkStackable {
    private let sequence = SequenceNumber(from: 0)
    let upstream: Upstream

    /// This is deliberately not exposed, to prevent framework
    /// consumers from accidentally breaking it.
    init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func data(_ request: URLRequestData) async throws -> URLResponseData {
        try await RequestMetadata.$number.withValue(sequence.next()) {
            try await upstream.data(request)
        }
    }
}

extension NetworkStackable {
    func numbered() -> Numbered<Self> {
        Numbered(upstream: self)
    }
}
