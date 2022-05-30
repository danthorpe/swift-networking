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

public struct RequestNumber: URLRequestOption {
    public static var defaultValue: Int = 0
}

extension URLRequestData {
    public internal(set) var number: Int {
        get { options[option: RequestNumber.self] }
        set { options[option: RequestNumber.self] = newValue }
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

    public func send(_ request: URLRequestData) async throws -> URLResponseData {
        var copy = request
        copy.number = await sequence.next()
        return try await upstream.send(request)
    }
}

extension NetworkStackable {
    func numbered() -> Numbered<Self> {
        Numbered(upstream: self)
    }
}
