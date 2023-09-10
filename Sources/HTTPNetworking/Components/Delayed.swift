import Dependencies

extension NetworkingComponent {
    public func delayed(by duration: Duration) -> some NetworkingComponent {
        modified(Delayed(duration: duration))
    }
}

struct Delayed: NetworkingModifier {
    @Dependency(\.continuousClock) var clock
    @NetworkEnvironment(\.instrument) var instrument

    let duration: Duration

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        ResponseStream { continuation in
            Task {
                do {
                    await instrument?.measureElapsedTime("Delay")
                    try await clock.sleep(for: duration)
                } catch {
                    continuation.finish(throwing: error)
                }

                await upstream.send(request).redirect(into: continuation)
            }
        }
    }
}
