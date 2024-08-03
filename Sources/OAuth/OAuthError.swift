import Foundation

extension OAuth {
  public enum Error: Swift.Error, Equatable {
    case oauthNotInstalled
    case invalidAuthorizationEndpoint(String)
    case invalidTokenEndpoint(String)

    case failedToCreateSecureRandomData
    case failedToCreateCodeChallengeForVerifier(String)
    case invalidAuthorizationURL(URLComponents)
    case invalidCallbackURL(URL)
    case failedToEncodeBodyForAccessToken(String)
  }
}
