import os.log

public enum NetworkLogger {
    @TaskLocal
    public static var logger: Logger?
}

extension NetworkingComponent {
    public func logged(
        onSend: @escaping @Sendable (HTTPRequestData) async -> Void,
        onSuccess: @escaping @Sendable (HTTPRequestData, HTTPResponseData, BytesReceived) async -> Void,
        onFailure: @escaping @Sendable (HTTPRequestData, Error) async -> Void
    ) -> some NetworkingComponent {
        modified(
            Logged(onSend: onSend, onSuccess: onSuccess, onFailure: onFailure, logger: nil)
        )
    }

    public func logged(using logger: Logger) -> some NetworkingComponent {
        modified(
            Logged(
                onSend: { request in
                    logger.info("↗️ \(request.debugDescription)")
                },
                onSuccess: { request, _, _ in
                    logger.info("↙️ 🆗 \(request.debugDescription)")
                },
                onFailure: { request, error in
                    logger.error("⚠️ \(request.debugDescription), error: \(String(describing: error))")
                },
                logger: logger
            )
        )
    }
}

struct Logged: NetworkingModifier {
    let onSend: @Sendable (HTTPRequestData) async -> Void
    let onSuccess: @Sendable (HTTPRequestData, HTTPResponseData, BytesReceived) async -> Void
    let onFailure: @Sendable (HTTPRequestData, Error) async -> Void
    let logger: Logger?

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        ResponseStream<HTTPResponseData> { continuation in
            Task {
                await NetworkLogger.$logger.withValue(logger) {
                    await onSend(request)
                    do {
                        for try await element in upstream.send(request) {
                            switch element {
                            case .progress:
                                continuation.yield(element)
                            case let .value(response, bytesReceived):
                                await onSuccess(request, response, bytesReceived)
                                continuation.yield(element)
                            }
                        }
                        continuation.finish()
                    } catch {
                        await onFailure(request, error)
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
}
