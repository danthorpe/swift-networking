import AuthenticationServices

public protocol OAuthProxy<Credentials>: Actor {
  associatedtype Credentials: BearerAuthenticatingCredentials, Sendable

  func set(credentials: Credentials)
  func set(didUpdateCredentials: @escaping @Sendable (Credentials) -> Void)
  func set(presentationContext: any ASWebAuthenticationPresentationContextProviding)
  func authorize() async throws
}
