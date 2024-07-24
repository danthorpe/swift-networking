import Foundation

extension AuthenticationMethod {
  public static let bearer = AuthenticationMethod(rawValue: "Bearer")
}

public protocol BearerAuthenticatingCredentials: AuthenticatingCredentials {}

extension BearerAuthenticatingCredentials {
  public static var method: AuthenticationMethod { .bearer }

  public func apply(token: String, to request: HTTPRequestData) -> HTTPRequestData {
    @NetworkEnvironment(\.logger) var logger
    var copy = request
    let authenticationValue = "Bearer \(token)"
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

public struct BearerCredentials: Hashable, Sendable, Codable, HTTPRequestDataOption, BearerAuthenticatingCredentials {
  public static let defaultOption: Self? = nil

  public let token: String

  public init(token: String) {
    self.token = token
  }

  public func apply(to request: HTTPRequestData) -> HTTPRequestData {
    apply(token: token, to: request)
  }
}

extension HTTPRequestData {
  public var bearerCredentials: BearerCredentials? {
    get { self[option: BearerCredentials.self] }
    set {
      self[option: BearerCredentials.self] = newValue
      self.authenticationMethod = .bearer
    }
  }
}

public typealias BearerAuthentication<
  Delegate: AuthenticationDelegate
> = HeaderBasedAuthentication<Delegate> where Delegate.Credentials == BearerCredentials
