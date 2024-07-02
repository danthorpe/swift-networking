public struct AuthenticationMethod: Hashable, RawRepresentable, Sendable, HTTPRequestDataOption {
  public static let defaultOption: Self? = nil

  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension HTTPRequestData {
  public var authenticationMethod: AuthenticationMethod? {
    get { self[option: AuthenticationMethod.self] }
    set { self[option: AuthenticationMethod.self] = newValue }
  }
}

extension NetworkingComponent {
  public func server(authenticationMethod: AuthenticationMethod) -> some NetworkingComponent {
    server { $0.authenticationMethod = authenticationMethod }
  }
}
