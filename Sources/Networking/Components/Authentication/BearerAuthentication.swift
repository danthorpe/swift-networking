import Foundation

extension AuthenticationMethod {
  public static let bearer = AuthenticationMethod(rawValue: "Bearer")
}

public struct BearerCredentials: Hashable, Sendable, Codable, HTTPRequestDataOption,
  AuthenticatingCredentials
{
  public static let method: AuthenticationMethod = .bearer
  public static let defaultOption: Self? = nil

  public let token: String

  public init(token: String) {
    self.token = token
  }

  public func apply(to request: HTTPRequestData) -> HTTPRequestData {
    var copy = request
    copy.headerFields[.authorization] = "Bearer \(token)"
    return copy
  }
}

extension HTTPRequestData {
  public var bearerCredentials: BearerCredentials? {
    get { self[option: BearerCredentials.self] }
    set { self[option: BearerCredentials.self] = newValue }
  }
}

public typealias BearerAuthentication<
  Delegate: AuthenticationDelegate
> = HeaderBasedAuthentication<Delegate> where Delegate.Credentials == BearerCredentials
