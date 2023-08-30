import Helpers

extension NetworkingComponent {
    public func duplicatesRemoved() -> some NetworkingComponent {
        modified(DuplicatesRemoved())
    }
}

private struct DuplicatesRemoved: NetworkingModifier {
    let activeRequests = ActiveRequests()
    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        ResponseStream { continuation in
            Task {
                let stream = await self.activeRequests.send(upstream: upstream, request: request)
                await stream.redirect(into: continuation)
            }
        }
    }
}

extension ActiveRequests {

    fileprivate func isDuplicate(request: HTTPRequestData) -> Value? {
        active.values.first(where: { $0.request ~= request })
    }

    fileprivate func send(
        upstream: NetworkingComponent,
        request: HTTPRequestData
    ) -> SharedStream {
        if let existing = isDuplicate(request: request) {
            NetworkLogger.logger?.info("👻 \(request.identifier) is a duplicate of \(existing.request.debugDescription)")
            return existing.stream
        }
        return add(stream: upstream.send(request), for: request)
    }
}
