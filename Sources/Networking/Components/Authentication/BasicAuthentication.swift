import Foundation

extension AuthenticationMethod {
  public static let basic = AuthenticationMethod(rawValue: "Basic")
}

public struct BasicCredentials: Hashable, Sendable, AuthenticatingCredentials, HTTPRequestDataOption {
  public static let method: AuthenticationMethod = .basic
  public static let defaultOption: Self? = nil

  public let user: String
  public let password: String

  public init(user: String, password: String) {
    self.user = user
    self.password = password
  }

  public func apply(to request: HTTPRequestData) -> HTTPRequestData {
    @NetworkEnvironment(\.logger) var logger
    var copy = request
    let joined = user + ":" + password
    let data = Data(joined.utf8)
    let encoded = data.base64EncodedString()
    let description = "Basic \(encoded)"
    logger?
      .info(
        """
        🔐 \(request.prettyPrintedIdentifier, privacy: .public) \
        Applying basic credentials: \(description, privacy: .private)
        """)
    copy.headerFields[.authorization] = description
    return copy
  }
}

extension HTTPRequestData {
  public var basicCredentials: BasicCredentials? {
    get { self[option: BasicCredentials.self] }
    set {
      self[option: BasicCredentials.self] = newValue
      self.authenticationMethod = .basic
    }
  }
}

extension AuthenticationDelegate {
  public static func basic(
    _ delegate: some AuthenticationDelegate<BasicCredentials>
  ) -> some AuthenticationDelegate<BasicCredentials> {
    AnyAuthenticationDelegate(
      delegate: ThreadSafeAuthenticationDelegate(
        delegate: delegate
      )
    )
  }
}
