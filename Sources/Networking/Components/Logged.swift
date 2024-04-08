import Dependencies
import os.log
import os.signpost

public typealias LogStart = @Sendable (HTTPRequestData) async -> Void
public typealias LogFailure = @Sendable (HTTPRequestData, Error) async -> Void
public typealias LogSuccess = @Sendable (HTTPRequestData, HTTPResponseData, BytesReceived) async ->
  Void

extension NetworkingComponent {

  public func logged(
    using logger: Logger,
    signposter: OSSignposter? = nil,
    onStart: LogStart? = nil,
    onFailure: LogFailure? = nil,
    onSuccess: LogSuccess? = nil
  ) -> some NetworkingComponent {
    let signposter = signposter ?? OSSignposter(logger: logger)
    return modified(
      Logged(
        signposter: signposter,
        onStart: onStart ?? {
          logger.info("↗️ \($0.debugDescription)")
          logger.debug("\($0.prettyPrintedHeaders, privacy: .private)")
          logger.debug("\($0.prettyPrintedBody)")
        },
        onFailure: onFailure ?? { request, error in
          logger.warning("⚠️ \(request.debugDescription), error: \(String(describing: error))")
        },
        onSuccess: onSuccess ?? { request, response, _ in
          logger.info("🆗 \(response.debugDescription)")
          if response.isNotCached {
            logger.debug("\(response.prettyPrintedHeaders, privacy: .private)")
            logger.debug("\(response.prettyPrintedBody)")
          }
          logger.info("↙️ \(request.debugDescription)")
        }
      )
    )
    .networkEnvironment(\.signposter) { signposter }
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

extension OSSignposter: NetworkEnvironmentKey {}

extension NetworkEnvironmentValues {
  public var signposter: OSSignposter? {
    get { self[OSSignposter.self] }
    set { self[OSSignposter.self] = newValue }
  }
}

struct Logged: NetworkingModifier {
  typealias OnStart = LogStart
  typealias OnFailure = LogFailure
  typealias OnSuccess = LogSuccess

  let signposter: OSSignposter
  let onStart: OnStart
  let onFailure: OnFailure
  let onSuccess: OnSuccess

  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    ResponseStream<HTTPResponseData> { continuation in
      Task {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("Start Network Request", id: id, "\(request.debugDescription)")
        defer {
          signposter.endInterval("Start Network Request", state)
        }
        await onStart(request)
        do {
          for try await element in upstream.send(request) {
            if case let .value(response, bytesReceived) = element {
              await onSuccess(response.request, response, bytesReceived)
            }
            continuation.yield(element)
          }
          signposter.emitEvent("End Network Request", id: id, "Success")
          continuation.finish()
        } catch {
          await onFailure(request, error)
          signposter.emitEvent("End Network Request", id: id, "Failure")
          continuation.finish(throwing: error)
        }
      }
    }
  }
}

struct SignpostIntervalData {
  let id: OSSignpostID
  let state: OSSignpostIntervalState
}
