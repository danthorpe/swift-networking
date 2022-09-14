import Foundation
import URLRouting

actor ActiveRequestsState {
    struct Key: Hashable {
        let id: URLRequestData.ID = RequestMetadata.id
        let number: Int = RequestMetadata.number
    }
    struct Value {
        let request: URLRequestData
        let task: Task<URLResponseData, Error>
    }

    private var active: [Key: Value] = [:]

    var count: Int { active.count }

    func existing(request: URLRequestData) -> Value? {
        active.values.first(where: { $0.request == request })
    }

    func add(_ task: Task<URLResponseData, Error>, for request: URLRequestData) {
        active[Key()] = Value(request: request, task: task)
    }

    func removeTask(for request: URLRequestData) {
        active[Key()] = nil
    }
}

protocol ActiveRequestable {
    var state: ActiveRequestsState { get }
}

extension ActiveRequestable {

    func submit<Upstream: NetworkStackable>(
        _ request: URLRequestData,
        using upstream: Upstream
    ) async -> Task<URLResponseData, Error> {
        let task = Task<URLResponseData, Error> {
            let result = try await upstream.data(request)
            await state.removeTask(for: request)
            return result
        }

        await state.add(task, for: request)

        return task
    }
}
