import Foundation

public protocol HTTPRequestDataOption {
    associatedtype Value
    static var defaultOption: Value { get }
    static var includeInEqualityEvaluation: Bool { get }
}

extension HTTPRequestDataOption {
    public static var includeInEqualityEvaluation: Bool {
        false
    }
}

struct HTTPRequestDataOptionContainer: @unchecked Sendable {
    let value: Any
    let isEqualTo: (Any?) -> Bool

    init(_ value: Any, isEqualTo: @escaping (Any?) -> Bool) {
        self.value = value
        self.isEqualTo = isEqualTo
    }
}
