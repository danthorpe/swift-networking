import Foundation
import os
import URLRouting

public enum ThrottleOption: URLRequestOption {
    public static var defaultValue: Self { .always }
    case always, never
}

extension ParserPrinter where Input == URLRequestData {
    func throttleOption(for route: Output) -> ThrottleOption {
        option(ThrottleOption.self, for: route)
    }
}

extension URLRequestData {
    var throttle: ThrottleOption {
        get { self[option: ThrottleOption.self] }
        set { self[option: ThrottleOption.self] = newValue }
    }
}

public actor Throttle<Upstream: HTTPLoadable>: HTTPLoadable {
    private var active: Set<HTTPRequest.ID> = []

    public let maximumNumberOfRequests: UInt
    public let upstream: Upstream

    public init(maximumNumberOfRequests: UInt = .max, upstream: Upstream) {
        self.maximumNumberOfRequests = maximumNumberOfRequests
        self.upstream = upstream
    }

    public convenience init(maximumNumberOfRequests max: UInt = .max, @HTTPLoaderBuilder _ build: () -> Upstream) {
        self.init(maximumNumberOfRequests: max, upstream: build())
    }

    private func checkActiveCountIsAtMax() -> Bool {
        UInt(active.count) >= maximumNumberOfRequests
    }

    private func addTaskWithId(_ id: HTTPRequest.ID) {
        active.insert(id)
        if let logger = Logger.current, checkActiveCountIsAtMax() {
            logger.info("⏸ Reached max count of tasks: \(self.active.count) with \(id)")
        }
    }

    private func removeTaskWithId(_ id: HTTPRequest.ID) {
        active.remove(id)
        if let logger = Logger.current, false == checkActiveCountIsAtMax(), active.count > 0 {
            logger.info("▶️ Available for more tasks: \(self.active.count) after \(id)")
        }
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {

        guard case .always = request.throttle else {
            return try await upstream.load(request)
        }

        // While the count of active requests is above our maximum
        // We can check for cancellation, and yield the Task
        while checkActiveCountIsAtMax() {
            try checkCancellation()
            await Task.yield()
        }

        // Check for cancellation again
        try checkCancellation()

        // Keep track of the active request
        addTaskWithId(request.id)

        // Remove the active task later
        defer { removeTaskWithId(request.id) }

        // Await the value
        return try await upstream.load(request)
    }
}

public extension HTTPLoadable {

    func throttle(maximumNumberOfRequests max: UInt = .max) -> Throttle<Self> {
        Throttle(maximumNumberOfRequests: max, upstream: self)
    }
}
