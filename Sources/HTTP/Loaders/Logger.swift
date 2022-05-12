import Foundation
import os.log

public extension Logger {
    @TaskLocal
    static var current: Self?
}

public struct Logged<Upstream: HTTPLoadable>: HTTPLoadable {
    public let logger: Logger
    public let upstream: Upstream

    @inlinable
    public init(logger: Logger, upstream: Upstream) {
        self.logger = logger
        self.upstream = upstream
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
        try await Logger.$current.withValue(logger) {
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
}

public extension HTTPLoadable {

    func log(using logger: Logger) -> Logged<Self> {
        Logged(logger: logger, upstream: self)
    }
}

