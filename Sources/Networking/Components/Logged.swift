import Dependencies
import os.log

public typealias LogStart = @Sendable (HTTPRequestData) async -> Void
public typealias LogFailure = @Sendable (HTTPRequestData, Error) async -> Void
public typealias LogSuccess = @Sendable (HTTPRequestData, HTTPResponseData, BytesReceived) async ->
  Void

extension NetworkingComponent {

  public func logged(
    using logger: Logger,
    onStart: LogStart? = nil,
    onFailure: LogFailure? = nil,
    onSuccess: LogSuccess? = nil
  ) -> some NetworkingComponent {
    modified(
      Logged(
        onStart: onStart ?? { logger.info("↗️ \($0.debugDescription)") },
        onFailure: onFailure ?? { request, error in
          logger.error("⚠️ \(request.debugDescription), error: \(String(describing: error))")
        },
        onSuccess: onSuccess ?? { request, response, _ in
          logger.info("🆗 \(response.debugDescription)")
          logger.info("↙️ \(request.debugDescription)")
        }
      )
    )
    .networkEnvironment(\.logger) { logger }
  }
}

extension Logger: NetworkEnvironmentKey {}

extension NetworkEnvironmentValues {
  public var logger: Logger? {
    get { self[Logger.self] }
    set { self[Logger.self] = newValue }
  }
}

struct Logged: NetworkingModifier {
  typealias OnStart = LogStart
  typealias OnFailure = LogFailure
  typealias OnSuccess = LogSuccess

  let onStart: OnStart
  let onFailure: OnFailure
  let onSuccess: OnSuccess

  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    ResponseStream<HTTPResponseData> { continuation in
      Task {
        await onStart(request)
        do {
          for try await element in upstream.send(request) {
            if case let .value(response, bytesReceived) = element {
              await onSuccess(response.request, response, bytesReceived)
            }
            continuation.yield(element)
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
