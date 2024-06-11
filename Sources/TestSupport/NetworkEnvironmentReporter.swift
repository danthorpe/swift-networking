import Helpers
import Networking

public actor NetworkEnvironmentReporter<Value: Sendable>: NetworkReportingComponent {
  let keyPath: KeyPath<NetworkEnvironmentValues, Value>
  public private(set) var start: Value?
  public private(set) var finish: Value?

  public init(keyPath: KeyPath<NetworkEnvironmentValues, Value>) {
    self.keyPath = keyPath
  }

  public func didStart(request: Networking.HTTPRequestData) {
    self.start = NetworkEnvironmentValues.current[keyPath: keyPath]
  }

  public func didFinish(request: HTTPRequestData) {
    self.finish = NetworkEnvironmentValues.current[keyPath: keyPath]
  }
}
