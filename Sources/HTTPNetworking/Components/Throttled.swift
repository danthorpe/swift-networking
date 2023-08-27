import AsyncAlgorithms
import Dependencies
import Foundation

public enum ThrottleOption: HTTPRequestDataOption {
    public static var defaultOption: Self { .always }
    case always, never
}

extension HTTPRequestData {
    public var throttle: ThrottleOption {
        get { self[option: ThrottleOption.self] }
        set { self[option: ThrottleOption.self] = newValue }
    }
}

extension NetworkingComponent {
    public func throttled(max: UInt) -> some NetworkingComponent {
        modified(Throttled(limit: max))
    }
}

struct Throttled: NetworkingModifier {

    let activeRequests = ActiveRequests()
    let limit: UInt

    init(limit: UInt) {
        self.limit = limit
    }

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        guard case .always = request.throttle else {
            return upstream.send(request)
        }
        return ResponseStream<HTTPResponseData> { continuation in
            Task {
                do {
                    try await activeRequests.send(
                        upstream: upstream,
                        request: request,
                        limit: self.limit
                    )
                    .redirect(into: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

extension ActiveRequests {

    fileprivate func send(
        upstream: NetworkingComponent,
        request: HTTPRequestData,
        limit: UInt
    ) async throws -> SharedStream {
        guard active.count >= limit else {
            return add(stream: upstream.send(request), for: request)
        }
        while active.count >= limit {
            // Co-operative cancellation
            try Task.checkCancellation()
            // Yield
            await Task.yield()
        }
        return add(stream: upstream.send(request), for: request)
    }
}
