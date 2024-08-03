import Foundation
import Networking

public protocol OAuthCredentials: Codable, Sendable, BearerAuthenticatingCredentials {
  var accessToken: String { get }
  var refreshToken: String { get }
}

extension OAuthCredentials {
  public func apply(to request: HTTPRequestData) -> HTTPRequestData {
    apply(token: accessToken, to: request)
  }
}
