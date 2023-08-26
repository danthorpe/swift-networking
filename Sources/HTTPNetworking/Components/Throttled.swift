import AsyncAlgorithms
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
            Task { [limit = self.limit] in
                do {
                    try await activeRequests.waitUntilCountLessThan(limit) { pendingRequests in
                        NetworkLogger.logger?.info("🧵 \(pendingRequests) requests")
                    }
                    await self.activeRequests.send(upstream: upstream, request: request)
                        .redirect(into: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

extension ActiveRequests {

    fileprivate func isDuplicate(request: HTTPRequestData) -> Value? {
        active.values.first(where: { $0.request ~= request })
    }

    fileprivate func send(
        upstream: NetworkingComponent,
        request: HTTPRequestData
    ) -> SharedStream {
        return add(stream: upstream.send(request), for: request)
    }
}
