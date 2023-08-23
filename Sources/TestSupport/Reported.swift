import HTTPNetworking
import Helpers

public typealias Reporter = @Sendable (HTTPRequestData) async -> Void

extension NetworkingComponent {
    public func reported(by reporter: @escaping Reporter) -> some NetworkingComponent {
        modified(Reported(reporter: reporter))
    }

    public func reported(by testReporter: TestReporter) -> some NetworkingComponent {
        reported { await testReporter.append(request: $0) }
    }
}

struct Reported: NetworkingModifier {
    let reporter: Reporter

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        ResponseStream { continuation in
            Task {
                await reporter(request)
                await upstream.send(request).redirect(into: continuation)
            }
        }
    }
}

// MARK: - Test Reporter

public actor TestReporter {
    public var requests: [HTTPRequestData] = []
    public init(
        requests: [HTTPRequestData] = []
    ) {
        self.requests = requests
    }

    public func append(request: HTTPRequestData) {
        self.requests.append(request)
    }
}
