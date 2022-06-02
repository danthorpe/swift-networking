import Foundation
import URLRouting

public struct ResetGuarded<Upstream: NetworkStackable>: NetworkStackable {

    actor State {
        var isResetting = false
        func startResetting() { isResetting = true }
        func stopResetting() { isResetting = false }
    }

    private let state = State()

    public let upstream: Upstream

    init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func data(_ request: URLRequestData) async throws -> URLResponseData {
        guard await !state.isResetting else {
            throw NetworkingError(.resetInProgress, request: request)
        }
        return try await upstream.data(request)
    }

    public func reset() async {
        await state.startResetting()
        await upstream.reset()
        await state.stopResetting()
    }
}

extension NetworkStackable {
    
    func guarded() -> ResetGuarded<Self> {
        ResetGuarded(upstream: self)
    }
}
