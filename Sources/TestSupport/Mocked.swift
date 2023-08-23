import HTTPNetworking

extension NetworkingComponent {
    public func mocked(
        _ request: HTTPRequestData,
        stub: StubbedResponseStream
    ) -> some NetworkingComponent {
        modified(Mocked(request: request, with: stub))
    }
}

struct Mocked: NetworkingModifier {
    let mock: HTTPRequestData
    let stub: StubbedResponseStream

    init(request: HTTPRequestData, with stubbedResponse: StubbedResponseStream) {
        self.mock = request
        self.stub = stubbedResponse
    }

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        guard request == mock else {
            return upstream.send(request)
        }
        return stub(request)
    }
}
