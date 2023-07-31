public enum Partial<Value, Progress> {
    case progress(Progress)
    case value(Value, Progress)

    public var value: Value? {
        guard case let .value(value, _) = self else {
            return nil
        }
        return value
    }

    public var progress: Progress {
        switch self {
        case .progress(let progress), .value(_, let progress):
            return progress
        }
    }

    public func onValue(perform block: (Value) throws -> Void) rethrows -> Partial<Value, Progress> {
        if case let .value(value, _) = self {
            try block(value)
        }
        return self
    }

    public func mapValue<NewValue>(transform: (Value) throws -> NewValue) rethrows -> Partial<NewValue, Progress> {
        switch self {
        case let .progress(progess):
            return .progress(progess)
        case let .value(value, progress):
            return try .value(transform(value), progress)
        }
    }

    public func mapProgress<NewProgress>(transform: (Progress) throws -> NewProgress) rethrows -> Partial<Value, NewProgress> {
        switch self {
        case let .progress(progress):
            return try .progress(transform(progress))
        case let .value(value, progress):
            return try .value(value, transform(progress))
        }
    }
}

extension Partial: Equatable where Value: Equatable, Progress: Equatable { }
extension Partial: Hashable where Value: Hashable, Progress: Hashable { }
extension Partial: Sendable where Value: Sendable, Progress: Sendable { }
