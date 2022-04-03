import Foundation
import os.log

public extension Logger {
    @TaskLocal
    static var current: Self?
}

/*
public struct HTTPLoadableLogEvents: OptionSet {
    public var rawValue: Int

    public static let started = HTTPLoadableLoggingEvent(rawValue: 1 << 0)
    public static let succeed = HTTPLoadableLoggingEvent(rawValue: 1 << 2)
    public static let failed = HTTPLoadableLoggingEvent(rawValue: 1 << 3)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public enum HTTPLoadableLogEventsOption: HTTPRequestOption {
    public static var defaultValue: HTTPLoadableLogEvents? = []
}

public extension HTTPRequest {
    var logEvents: HTTPLoadableLogEvents? {
        get { self[option: HTTPLoadableLogEventsOption.self] }
        set { self[option: HTTPLoadableLogEventsOption.self] = newValue }
    }
}
*/

public struct Logged<Upstream: HTTPLoadable>: HTTPLoadable {
    public let upstream: Upstream

    @inlinable
    public init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let logger = Logger.current else {
            return try await upstream.load(request)
        }
        do {
            logger.info("↗️ \(request.path)")
            let response = try await upstream.load(request)
            logger.info("↙️ \(request.path), success")
            return response
        }
        catch {
            logger.error("⚠️ \(request.path), error: \(String(describing: error))")
            throw error
        }
    }
}

public extension HTTPLoadable {

    func log(using logger: Logger) -> Logged<Self> {
        Logger.$current.withValue(logger) {
            Logged(upstream: self)
        }
    }
}

