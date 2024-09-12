import AuthenticationServices
import ConcurrencyExtras
import Dependencies
import Helpers
import Networking
import Protected

extension NetworkingComponent {

  public func authenticated<Credentials: OAuthCredentials>(
    oauth: some OAuthSystem<Credentials>
  ) -> some NetworkingComponent {

    let delegate = ThreadSafeAuthenticationDelegate(
      delegate: StreamingAuthenticationDelegate(
        delegate: OAuth.Delegate<Credentials>(
          upstream: self,
          system: oauth
        )
      )
    )
    OAuth.InstalledSystems.set(
      oauth: OAuth.Proxy(delegate: delegate)
    )
    return server(authenticationMethod: Credentials.method)
      .authenticated(with: delegate)
  }

  public func oauth<ReturnValue: Sendable, Credentials: OAuthCredentials>(
    of credentialsType: Credentials.Type,
    perform: @MainActor (any OAuthProxy<Credentials>) async throws -> ReturnValue
  ) async throws -> ReturnValue {
    guard let oauth = OAuth.InstalledSystems.oauth(as: Credentials.self) else {
      throw OAuth.Error.oauthNotInstalled
    }
    return try await perform(oauth)
  }
}
