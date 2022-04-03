
import Foundation

public enum ThrottleOption: HTTPRequestOption {
    public static var defaultValue: Self { .always }
    case always, never
}

extension HTTPRequest {
    public var throttle: ThrottleOption {
        get { self[option: ThrottleOption.self] }
        set { self[option: ThrottleOption.self] = newValue }
    }
}

public actor Throttle<Upstream: HTTPLoadable>: HTTPLoadable {
    private var active: [HTTPRequest.ID: LoadableTask] = [:]

    public var maximumNumberOfRequests = UInt.max
    public let upstream: Upstream

    @inlinable
    public init(maximumNumberOfRequests: UInt = .max, upstream: Upstream) {
        self.maximumNumberOfRequests = maximumNumberOfRequests
        self.upstream = upstream
    }

    @inlinable
    convenience init(maximumNumberOfRequests max: UInt = .max, @HTTPLoaderBuilder _ build: () -> Upstream) {
        self.init(maximumNumberOfRequests: max, upstream: build())
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {

        // Check the throttle option on the request
        guard case .always = request.throttle else {
            return try await upstream.load(request)
        }

        // While the count of active requests is above our maximum
        // We can check for cancellation, and yield the Task
        while UInt(active.count) > maximumNumberOfRequests {
            try checkCancellation()
            await Task.yield()
        }

        // Check for cancellation again
        try checkCancellation()

        let task = upstream.send(request)

        // Keep track of the active tasks
        active[request.id] = task
        defer { active[request.id] = task }

        return try await task.value
    }
}

public extension HTTPLoadable {

    func throttle(maximumNumberOfRequests max: UInt = .max) -> Throttle<Self> {
        Throttle(maximumNumberOfRequests: max, upstream: self)
    }
}
