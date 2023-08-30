import HTTPNetworking
import XCTestDynamicOverlay

public struct TerminalNetworkingComponent: NetworkingComponent {
    public struct TestFailure: Equatable, Error {
        public let request: HTTPRequestData
    }
    let isFailingTerminal: Bool
    public init(
        isFailingTerminal: Bool = true
    ) {
        self.isFailingTerminal = isFailingTerminal
    }
    public func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        ResponseStream { continuation in
            if isFailingTerminal {
                XCTFail("\(request.debugDescription) reached the Failing Network Component")
                continuation.finish(throwing: TestFailure(request: request))
            } else {
                continuation.finish()
            }
        }
    }
}