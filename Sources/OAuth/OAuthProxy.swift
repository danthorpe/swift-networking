import AuthenticationServices
import Networking

public protocol OAuthProxy<Credentials>: Actor {
  associatedtype Credentials: BearerAuthenticatingCredentials, Sendable

  func set(presentationContext: any ASWebAuthenticationPresentationContextProviding) async
  func set(credentials: Credentials) async
  func signIn() async throws
  func signOut() async
  func subscribeToCredentialsDidChange(_ credentialsDidChange: (Credentials) async -> Void) async
}
