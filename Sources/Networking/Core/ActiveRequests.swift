import Foundation
import URLRouting

actor ActiveRequestsState {
    struct Key: Hashable {
        let id: URLRequestData.ID
        let number: Int
    }
    struct Value {
        let request: URLRequestData
        let task: Task<URLResponseData, Error>
    }

    private var active: [Key: Value] = [:]

    var count: Int { active.count }

    func index(of request: URLRequestData) -> Int {
        guard let index = active.keys
            .sorted(by: { $0.number < $1.number })
            .map(\.id)
            .firstIndex(of: RequestMetadata.id)
        else {
            fatalError("Expected to find index for \(request.description) in active requests.")
        }
        print("\(request.description) index: \(index) out of \(active.count)")
        return index
    }

    func existing(request: URLRequestData) -> Value? {
        active.values.first(where: { $0.request == request })
    }

    func add(_ task: Task<URLResponseData, Error>, for request: URLRequestData) {
        active[Key(id: RequestMetadata.id, number: RequestMetadata.number)] = Value(request: request, task: task)
    }

    func removeTask(for request: URLRequestData) {
        active[Key(id: RequestMetadata.id, number: RequestMetadata.number)] = nil
    }
}

protocol ActiveRequestable {
    var state: ActiveRequestsState { get }
}

extension ActiveRequestable {

    func submit<Upstream: NetworkStackable>(_ request: URLRequestData, using upstream: Upstream) async -> Task<URLResponseData, Error> {
        let task = Task<URLResponseData, Error> {
            let result = try await upstream.data(request)
            await state.removeTask(for: request)
            return result
        }

        await state.add(task, for: request)

        return task
    }
}
