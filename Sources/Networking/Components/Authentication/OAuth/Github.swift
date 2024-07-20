import AuthenticationServices

@available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *)
public struct GitHubOAuthSystem: OAuthSystem {
  public let clientSecret = OAuth.ClientSecret.pkce
  public let callback: ASWebAuthenticationSession.Callback
  public let clientId: String
  public var authorizationServer: String = "https://github.com/login/oauth/authorize"
  public var scope: String?

  init(
    callback: ASWebAuthenticationSession.Callback,
    clientId: String,
    scope: String? = nil
  ) {
    self.callback = callback
    self.clientId = clientId
    self.scope = scope
  }
}

@available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *)
extension OAuthSystem where Self == GitHubOAuthSystem {

  public static func github(
    client: String,
    scope: String? = nil,
    callback: ASWebAuthenticationSession.Callback
  ) -> any OAuthSystem {
    GitHubOAuthSystem(callback: callback, clientId: client, scope: scope)
  }
}
