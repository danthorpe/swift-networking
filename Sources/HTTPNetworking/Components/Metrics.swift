import Dependencies
import Clocks
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
        let measurement = ElapsedTimeMeasurement(
            label: label,
            duration: previous.duration(to: now),
            instant: now
        )
        measurements.append(measurement)
    }
}

public struct ElapsedTimeMeasurement: Equatable {
    public let label: String
    public let duration: Duration
    let instant: AnyClock<Duration>.Instant

    public init(label: String, duration: Duration, instant: AnyClock<Duration>.Instant) {
        self.label = label
        self.duration = duration
        self.instant = instant
    }
}

public struct NetworkingInstrumentClient {
    public var elapsedTimeMeasurements: @Sendable () async -> [ElapsedTimeMeasurement]
    public var measureElapsedTime: @Sendable (String) async -> Void
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
