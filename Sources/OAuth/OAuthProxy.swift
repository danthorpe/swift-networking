import AuthenticationServices
import Networking

public protocol OAuthProxy<Credentials>: Actor {
  associatedtype Credentials: OAuthCredentials, Sendable

  func set(presentationContext: any ASWebAuthenticationPresentationContextProviding) async
  func set(credentials: Credentials) async
  func signIn() async throws
  func signOut() async
  func subscribeToCredentialsDidChange(_ credentialsDidChange: (Credentials) async -> Void) async
}

extension OAuth {
  actor Proxy<Credentials: OAuthCredentials>: OAuthProxy {
    typealias Delegate = ThreadSafeAuthenticationDelegate<
      StreamingAuthenticationDelegate<OAuth.Delegate<Credentials>>
    >

    let delegate: Delegate

    init(delegate: Delegate) {
      self.delegate = delegate
    }

    func set(credentials: Credentials) async {
      await delegate.set(credentials: credentials)
    }

    func set(presentationContext: any ASWebAuthenticationPresentationContextProviding) async {
      await delegate.delegate.delegate.set(presentationContext: presentationContext)
    }

    func subscribeToCredentialsDidChange(_ credentialsDidChange: (Credentials) async -> Void) async {
      for await credentials in await delegate.delegate.credentials {
        await credentialsDidChange(credentials)
      }
    }

    func signIn() async throws {
      _ = try await delegate.authorize()
    }

    func signOut() async {
      await delegate.removeCredentials()
    }
  }
}
