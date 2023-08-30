import Foundation
import os.log
import URLRouting

public struct RemoveDuplicates<Upstream: NetworkStackable>: NetworkStackable, ActiveRequestable {
    let state = ActiveRequestsState()

    public let upstream: Upstream

    public init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func data(_ request: URLRequestData) async throws -> URLResponseData {
        if let existing = await state.existing(request: request) {
            if let logger = Logger.current {
                logger.info("👻 Duplicate of: \(existing.request.description)")
            }
            return try await existing.task.value
        }

        return try await submit(request, using: upstream).value
    }
}

public extension NetworkStackable {
    func removeDuplicates() -> RemoveDuplicates<Self> {
        RemoveDuplicates(upstream: self)
    }
}
