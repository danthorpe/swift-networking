import Foundation

extension OAuth {
  public enum Error: Swift.Error, Equatable {
    case oauthNotInstalled
    case failedToCreateSecureRandomData
    case failedToCreateCodeChallengeForVerifier(String)
    case invalidAuthorizationService
    case invalidAuthorizationURL(URLComponents)
    case invalidCallbackURL(URL)
    case failedToEncodeBodyForAccessToken(String)
  }
}
