import Foundation
import URLRouting

actor ActiveRequestsData {
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
            .firstIndex(of: request.id)
        else {
            fatalError("Expected to find index for \(request.description) in active requests.")
        }
        print("\(request.description) index: \(index) out of \(active.count)")
        return index
    }

    func add(_ task: Task<URLResponseData, Error>, for request: URLRequestData) -> Int {
        active[Key(id: request.id, number: request.number)] = Value(request: request, task: task)
        return active.count
    }

    func removeTask(for request: URLRequestData) {
        active[Key(id: request.id, number: request.number)] = nil
    }
}
