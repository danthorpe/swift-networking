import Foundation

public protocol HTTPResponseMetadata {
    associatedtype Value
    static var defaultMetadata: Value { get }
    static var includeInEqualityEvaluation: Bool { get }
}

extension HTTPResponseMetadata {
    public static var includeInEqualityEvaluation: Bool {
        false
    }
}

struct HTTPResponseMetadataContainer: @unchecked Sendable {
    let value: Any
    let isEqualTo: (Any?) -> Bool

    init(_ value: Any, isEqualTo: @escaping (Any?) -> Bool) {
        self.value = value
        self.isEqualTo = isEqualTo
    }
}
