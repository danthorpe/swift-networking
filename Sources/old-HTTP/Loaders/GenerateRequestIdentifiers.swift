import Foundation
import Tagged
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
    var number: Int {
        get { options[option: RequestNumber.self] }
        set { options[option: RequestNumber.self] = newValue }
    }
}

public extension URLRequestData {
    typealias ID = Tagged<URLRequestData, String>
}

public struct RequestID: URLRequestOption {
    public static var defaultValue: URLRequestData.ID = "undefined-request-id"
}

extension URLRequestData {
    var id: URLRequestData.ID {
        get { options[option: RequestID.self] }
        set { options[option: RequestID.self] = newValue }
    }
}

public struct GenerateRequestIdentifiers<Upstream: HTTPLoadable>: HTTPLoadable {
    public let upstream: Upstream

    private let sequence = SequenceNumber(from: 0)

    /// This is deliberately not exposed, to prevent framework
    /// consumers from accidentally breaking it.
    init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func load(_ request: URLRequestData) async throws -> (Data, URLResponse) {
        var copy = request
        copy.number = await sequence.next()
        copy.id = .init(rawValue: UUID().uuidString)
        return try await upstream.load(copy)
    }
}
