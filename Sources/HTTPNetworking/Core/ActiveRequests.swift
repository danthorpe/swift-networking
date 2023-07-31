actor ActiveRequests {
    struct Key: Hashable {
        let id: HTTPRequestData.ID
        let number = RequestSequence.number
    }
    struct Value {
        let request: HTTPRequestData
        let stream: ResponseStream<HTTPResponseData>
    }

    private var active: [Key: Value] = [:]

    var count: Int { active.count }

    func firstExisting(request: HTTPRequestData) -> Value? {
        active.values.first(where: { $0.request == request })
    }

    func add(
        stream: ResponseStream<HTTPResponseData>,
        for request: HTTPRequestData
    ) {
        guard nil == firstExisting(request: request) else { return }
        active[Key(id: request.id)] = Value(request: request, stream: stream)
    }

    func removeStream(for request: HTTPRequestData) {
        active[Key(id: request.id)] = nil
    }

    func waitUntilCountLessThan(_ limit: UInt, countDidChange: @Sendable (Int) async -> Void) async throws {
        var initial = active.count
        while active.count > limit {
            try Task.checkCancellation()
            let latest = active.count
            if initial > latest {
                initial = latest
                await countDidChange(latest)
            }
            await Task.yield()
        }
    }
}

protocol ActiveRequestable {
    var activeRequests: ActiveRequests { get }
}

extension ActiveRequestable {
    func stream<Upstream: NetworkingComponent>(
        _ request: HTTPRequestData,
        using upstream: Upstream
    ) async throws -> ResponseStream<HTTPResponseData> {
        let existing = await activeRequests.firstExisting(request: request)
        guard nil == existing else {
            throw "TODO: Unexpected existing stream for request"
        }
        let stream = ResponseStream<HTTPResponseData> { continuation in
            upstream.send(request)
                .redirect(into: continuation, onTermination: {
                    await activeRequests.removeStream(for: request)
                })
        }
        await activeRequests.add(stream: stream, for: request)
        return stream
    }

    func waitUntilCountLessThan(_ limit: UInt, countDidChange: @Sendable (Int) async -> Void) async throws {
        try await activeRequests
            .waitUntilCountLessThan(limit, countDidChange: countDidChange)
    }
}
