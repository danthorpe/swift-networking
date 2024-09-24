import Foundation
import HTTPTypes
import Networking

extension AuthenticationMethod {
  public static let spotify = AuthenticationMethod(rawValue: "spotify")
}

extension OAuth.AvailableSystems {
  public struct Spotify: StandardOAuthSystem {
    public struct Credentials: OAuthCredentials {
      public enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case tokenType = "token_type"
      }
      public static let method: AuthenticationMethod = .spotify
      public let accessToken: String
      public let expiresIn: Int
      public let refreshToken: String
      public let scope: String?
      public let tokenType: String
      public init(accessToken: String, expiresIn: Int, refreshToken: String, scope: String?, tokenType: String) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.scope = scope
        self.tokenType = tokenType
      }
    }

    public let authorizationEndpoint = "https://accounts.spotify.com/authorize"
    public let tokenEndpoint = "https://accounts.spotify.com/api/token"

    public let clientId: String
    public let redirectURI: String
    public let scope: String?
  }
}

extension OAuthSystem where Self == OAuth.AvailableSystems.Spotify {
  public static func spotify(
    clientId: String,
    callback: String,
    scope: String? = nil
  ) -> Self {
    OAuth.AvailableSystems.Spotify(clientId: clientId, redirectURI: callback, scope: scope)
  }
}

extension NetworkingComponent {
  public func spotify<ReturnValue>(
    perform: (any OAuthProxy<OAuth.AvailableSystems.Spotify.Credentials>) async throws -> ReturnValue
  ) async throws -> ReturnValue {
    try await oauth(of: OAuth.AvailableSystems.Spotify.Credentials.self, perform: perform)
  }
}
