import AuthenticationServices

public protocol OAuthProxy<Credentials>: Actor {
  associatedtype Credentials: BearerAuthenticatingCredentials, Sendable

  func subscribeToCredentialsDidChange(_ credentialsDidChange: (Credentials) async -> Void) async
  func set(presentationContext: any ASWebAuthenticationPresentationContextProviding) async
  func signIn() async throws
}
