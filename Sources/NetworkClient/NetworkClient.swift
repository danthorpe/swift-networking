import Dependencies
import DependenciesMacros
import Networking

@DependencyClient
public struct NetworkClient: Sendable {
  public var networkClient: @Sendable () -> any NetworkingComponent = { Networking.Unimplemented() }
}

extension NetworkClient: TestDependencyKey {
  public static let testValue = NetworkClient()
}

extension DependencyValues {
  public var networkClient: NetworkClient {
    get { self[NetworkClient.self] }
    set { self[NetworkClient.self] = newValue }
  }
}
