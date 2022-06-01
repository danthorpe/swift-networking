import Foundation
import os
import URLRouting

public extension Logger {
    @TaskLocal
    static var current: Self?
}

public struct Logged<Upstream: NetworkStackable> {
    public let logger: Logger
    public let upstream: Upstream

    @inlinable
    public init(logger: Logger, upstream: Upstream) {
        self.logger = logger
        self.upstream = upstream
    }
}

extension Logged: NetworkStackable {

    public func send(_ request: URLRequestData) async throws -> URLResponseData {
        let desc = request.description
        return try await Logger.$current.withValue(logger) {
            do {
                logger.info("↗️ \(desc)")
                let response = try await upstream.send(request)
                logger.info("↙️ 🆗 \(desc)")
                return response
            }
            catch {
                logger.error("⚠️ \(desc), error: \(String(describing: error))")
                throw error
            }
        }
    }
}

public extension NetworkStackable {

    func use(logger: Logger) -> Logged<Self> {
        Logged(logger: logger, upstream: self)
    }
}

