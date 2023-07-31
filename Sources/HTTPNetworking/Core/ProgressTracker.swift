actor ProgressTracker: Sendable {
    private var tasks: [AnyHashable: BytesReceived] = [:]

    func set(id: some Hashable & Sendable, bytesReceived: BytesReceived) {
        tasks[id] = bytesReceived
    }

    func remove(id: AnyHashable) {
        tasks[id] = nil
    }

    func overall() -> BytesReceived {
        tasks.values.reduce(BytesReceived(), +)
    }

    func fractionCompleted() -> Double {
        overall().fractionCompleted
    }
}
