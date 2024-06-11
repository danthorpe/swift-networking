import ConcurrencyExtras
import Dependencies
import os.log
import os.signpost

public typealias LogStart = @Sendable (Logger, HTTPRequestData) async -> Void
public typealias LogFailure = @Sendable (Logger, HTTPRequestData, Error) async -> Void
public typealias LogSuccess = @Sendable (Logger, HTTPRequestData, HTTPResponseData, BytesReceived) async ->
  Void

extension NetworkingComponent {

  public func logged(
    using logger: Logger,
    signposter: OSSignposter? = nil,
    onStart: LogStart? = nil,
    onFailure: LogFailure? = nil,
    onSuccess: LogSuccess? = nil
  ) -> some NetworkingComponent {
    modified(
      Logged(
        logger: logger,
        signposter: signposter ?? OSSignposter(logger: logger),
        onStart: onStart ?? { logger, request in
          logger.info("↗️ \(request.debugDescription)")
          logger.debug("\(request.prettyPrintedHeaders, privacy: .private)")
          logger.debug("\(request.prettyPrintedBody)")
        },
        onFailure: onFailure ?? { logger, request, error in
          logger.warning("⚠️ \(request.debugDescription), error: \(String(describing: error))")
        },
        onSuccess: onSuccess ?? { logger, request, response, _ in
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

extension Logger: @unchecked Sendable, NetworkEnvironmentKey {}

extension NetworkEnvironmentValues {
  public var logger: Logger? {
    get { self[Logger.self] }
    set { self[Logger.self] = newValue }
  }
}

extension OSSignposter: @unchecked Sendable, NetworkEnvironmentKey {}

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

  let logger: Logger
  let signposter: OSSignposter
  let onStart: OnStart
  let onFailure: OnFailure
  let onSuccess: OnSuccess

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    ResponseStream<HTTPResponseData> { continuation in
      Task {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("Start Network Request", id: id, "\(request.debugDescription)")
        defer {
          signposter.endInterval("Start Network Request", state)
        }
        await onStart(logger, request)
        do {
          for try await element in upstream.send(request) {
            if case let .value(response, bytesReceived) = element {
              await onSuccess(logger, response.request, response, bytesReceived)
            }
            continuation.yield(element)
          }
          signposter.emitEvent("End Network Request", id: id, "Success")
          continuation.finish()
        } catch {
          await onFailure(logger, request, error)
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
