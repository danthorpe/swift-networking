
import Foundation

public struct ResetGuard<Upstream: HTTPLoadable>: HTTPLoadable {

    actor State {
        var isResetting = false

        func startResetting() {
            isResetting = true
        }

        func stopResetting() {
            isResetting = false
        }
    }

    public let upstream: Upstream
    private let state = State()

    public init(upstream: Upstream) {
        self.upstream = upstream
    }

    public init(@HTTPLoaderBuilder _ build: () -> Upstream) {
        self.init(upstream: build())
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
        if await state.isResetting {
            throw HTTPError(.resetInProgress, request: request)
        }

        return try await upstream.load(request)
    }

    public func reset() async {
        await state.startResetting()
        await upstream.reset()
        await state.stopResetting()
    }
}

public extension HTTPLoadable {

    func resetGuard() -> ResetGuard<Self> {
        ResetGuard(upstream: self)
    }
}
