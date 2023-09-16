import Networking
import Helpers

public protocol NetworkReportingComponent: Actor {
    func didStart(request: HTTPRequestData)
    func didFinish(request: HTTPRequestData)
}

extension NetworkReportingComponent {
    public func didFinish(request: HTTPRequestData) { }
}

extension NetworkingComponent {
    public func reported(by testReporter: any NetworkReportingComponent) -> some NetworkingComponent {
        modified(Reported(reporter: testReporter))
    }
}

struct Reported: NetworkingModifier {
    let reporter: any NetworkReportingComponent
    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        ResponseStream { continuation in
            Task {
                await reporter.didStart(request: request)
                await upstream.send(request)
                    .redirect(into: continuation, onTermination: {
                        await reporter.didFinish(request: request)
                    })
            }
        }
    }
}

// MARK: - Test Reporter

public actor TestReporter: NetworkReportingComponent {
    public var requests: [HTTPRequestData] = []
    public var activeRequests: [HTTPRequestData] {
        didSet {
            peakActiveRequests = max(peakActiveRequests, activeRequests.count)
        }
    }
    public var peakActiveRequests: Int = 0
    public init(
        requests: [HTTPRequestData] = [],
        activeRequests: [HTTPRequestData] = []
    ) {
        self.requests = requests
        self.activeRequests = requests
    }

    public func didStart(request: HTTPRequestData) {
        self.requests.append(request)
        self.activeRequests.append(request)
    }

    public func didFinish(request: HTTPRequestData) {
        self.activeRequests.removeAll { $0.id == request.id }
    }
}
