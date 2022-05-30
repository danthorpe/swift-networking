import Foundation
import URLRouting

typealias HTTPTask = Task<(Data, URLResponse), HTTPError>

actor RemoveDuplicatesData {

}

public struct RemoveDuplicates<Upstream: HTTPLoadable>: HTTPLoadable {

    let state = RemoveDuplicatesData()

    public let upstream: Upstream

    public init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func load(_ request: URLRequestData) async throws -> (Data, URLResponse) {
/*
        func handleActiveTask(_ task: LoadableTask, for id: HTTPRequest.ID) async throws -> HTTPResponse {
            await state.removeActiveTask(for: id)
            return try await task.value
        }

        if let task = await state.active[request.id] {
            return try await handleActiveTask(task, for: request.id)
        }

        let task = upstream.send(request)
        await state.saveActiveTask(task, for: request.id)
        return try await handleActiveTask(task, for: request.id)
*/
    }
}
