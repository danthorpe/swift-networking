import Foundation

public struct RemoveDuplicates<Upstream: HTTPLoadable>: HTTPLoadable {

    actor State {
        var active: [HTTPRequest.ID: LoadableTask] = [:]

        func removeActiveTask(for id: HTTPRequest.ID) {
            active[id] = nil
        }

        func saveActiveTask(_ task: LoadableTask, for id: HTTPRequest.ID) {
            active[id] = task
        }
    }

    let state = State()

    public let upstream: Upstream

    public init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {

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
    }
}
