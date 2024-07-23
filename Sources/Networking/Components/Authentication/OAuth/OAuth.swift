import Foundation

public enum OAuth { /* Namespace */  }

extension OAuth {
  public enum ClientSecret: Sendable {
    case secret(String)
    case pkce
  }

  public enum Error: Swift.Error, Equatable {
    case oauthNotInstalled
    case failedToCreateSecureRandomData
    case failedToCreateCodeChallengeForVerifier(String)
    case invalidAuthorizationService(String)
    case invalidAuthorizationURL(URLComponents)
    //    case webAuthenticationSessionError(any Swift.Error)
  }
}
