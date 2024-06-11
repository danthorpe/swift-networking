import Clocks
import Dependencies
import Foundation

extension NetworkingComponent {
  public func instrument() -> some NetworkingComponent {
    networkEnvironment(\.instrument) {
      @Dependency(\.continuousClock) var clock
      return NetworkingInstrumentClient(NetworkingInstrument(clock: clock))
    }
  }
}

private actor NetworkingInstrument {

  let clock: AnyClock<Duration>
  let start: ElapsedTimeMeasurement
  var end: ElapsedTimeMeasurement?
  var measurements: [ElapsedTimeMeasurement] = []

  init(clock: any Clock<Duration>) {
    self.clock = AnyClock(clock)
    self.start = .init(label: "start", duration: .zero, instant: AnyClock(clock).now)
  }

  func measureElapsedTime(label: String) {
    let now = clock.now
    let previous = measurements.last?.instant ?? start.instant
    let duration = previous.duration(to: now)
    let measurement = ElapsedTimeMeasurement(
      label: label,
      duration: duration,
      instant: now
    )
    measurements.append(measurement)

    @NetworkEnvironment(\.logger) var logger
    let total = measurements.total
    logger?.info("⏱️ \(label) \(duration.description) total: \(total.description)")
  }
}

public struct ElapsedTimeMeasurement: Equatable, Sendable {
  public let label: String
  public let duration: Duration
  let instant: AnyClock<Duration>.Instant

  public init(label: String, duration: Duration, instant: AnyClock<Duration>.Instant) {
    self.label = label
    self.duration = duration
    self.instant = instant
  }
}

public struct NetworkingInstrumentClient: Sendable {
  public let elapsedTimeMeasurements: @Sendable () async -> [ElapsedTimeMeasurement]
  public let measureElapsedTime: @Sendable (String) async -> Void
}

extension [ElapsedTimeMeasurement] {
  var total: Duration {
    map(\.duration).reduce(.zero, +)
  }
}

extension NetworkingInstrumentClient: NetworkEnvironmentKey {
  fileprivate init(_ instrument: NetworkingInstrument) {
    self.init(
      elapsedTimeMeasurements: {
        await instrument.measurements
      },
      measureElapsedTime: {
        await instrument.measureElapsedTime(label: $0)
      }
    )
  }
}

extension NetworkEnvironmentValues {
  public var instrument: NetworkingInstrumentClient? {
    get { self[NetworkingInstrumentClient.self] }
    set { self[NetworkingInstrumentClient.self] = newValue }
  }
}
