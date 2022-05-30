
import Foundation

extension Loaders {

    public enum Conditional<First: HTTPLoadable, Second: HTTPLoadable>: HTTPLoadable {
        case first(First)
        case second(Second)

        @inlinable
        public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
            switch self {
            case let .first(loader):
                return try await loader.load(request)
            case let .second(loader):
                return try await loader.load(request)
            }
        }
    }

}
