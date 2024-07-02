extension AuthenticationMethod {
  public static let oauth = AuthenticationMethod(rawValue: "OAuth")
}

extension OAuth {
  public struct Credentials: AuthenticatingCredentials {
    public static let method: AuthenticationMethod = .oauth

    public let access: String
    public let refresh: String

    public init(access: String, refresh: String) {
      self.access = access
      self.refresh = refresh
    }

    public func apply(to request: HTTPRequestData) -> HTTPRequestData {
      @NetworkEnvironment(\.logger) var logger
      var copy = request
      let authenticationValue = "Bearer \(access)"
      logger?
        .info(
          """
          🔐 \(request.prettyPrintedIdentifier, privacy: .public) \
          Applying bearer credentials: \(authenticationValue, privacy: .private)
          """)
      copy.headerFields[.authorization] = authenticationValue
      return copy
    }
  }
}
