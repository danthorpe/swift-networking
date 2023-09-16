import Networking

extension NetworkingComponent {
    public func mocked(
        _ request: HTTPRequestData,
        stub: StubbedResponseStream
    ) -> some NetworkingComponent {
        modified(Mocked(request: request, with: stub))
    }

    public func mocked(
        _ block: @escaping @Sendable (NetworkingComponent, HTTPRequestData) -> ResponseStream<HTTPResponseData>
    ) -> some NetworkingComponent {
        modified(CustomMocked(block: block))
    }
}

struct Mocked: NetworkingModifier {
    let mock: HTTPRequestData
    let stub: StubbedResponseStream

    @NetworkEnvironment(\.instrument) var instrument

    init(request: HTTPRequestData, with stubbedResponse: StubbedResponseStream) {
        self.mock = request
        self.stub = stubbedResponse
    }

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        guard request ~= mock else {
            return upstream.send(request)
        }
        return ResponseStream { continuation in
            Task {
                await instrument?.measureElapsedTime("Mocked")
                await stub(request).redirect(into: continuation)
            }
        }
    }
}

struct CustomMocked: NetworkingModifier {
    let block: @Sendable (NetworkingComponent, HTTPRequestData) -> ResponseStream<HTTPResponseData>

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        block(upstream, request)
    }
}
