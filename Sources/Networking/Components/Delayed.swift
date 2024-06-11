import Dependencies
import os.log

extension NetworkingComponent {
  public func delayed(by duration: Duration) -> some NetworkingComponent {
    modified(Delayed(duration: duration))
  }
}

struct Delayed: NetworkingModifier {
  @Dependency(\.continuousClock) var clock
  @NetworkEnvironment(\.instrument) var instrument
  @NetworkEnvironment(\.logger) var logger

  let duration: Duration

  func send(upstream: some NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    ResponseStream { continuation in
      Task {
        do {
          await instrument?.measureElapsedTime("Delay")
          if duration > .zero {
            logger?.info("⏳ \(request.debugDescription) delay for \(duration)")
          }
          try await clock.sleep(for: duration)
        } catch {
          continuation.finish(throwing: error)
        }

        upstream.send(request).redirect(into: continuation)
      }
    }
  }
}
