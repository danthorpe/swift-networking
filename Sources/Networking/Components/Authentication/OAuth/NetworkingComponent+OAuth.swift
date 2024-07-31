import AuthenticationServices
import ConcurrencyExtras
import Dependencies
import Helpers
import Protected

extension NetworkingComponent {

  public func authenticated<Credentials: BearerAuthenticatingCredentials>(
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
    OAuth.InstalledSystems.set(oauth: OAuth.Proxy(delegate: delegate))
    return authenticated(with: delegate)
  }

  public func oauth<ReturnValue: Sendable, Credentials: BearerAuthenticatingCredentials>(
    of credentialsType: Credentials.Type,
    perform: @MainActor (any OAuthProxy<Credentials>) async throws -> ReturnValue
  ) async throws -> ReturnValue {
    guard let oauth = OAuth.InstalledSystems.oauth(as: Credentials.self) else {
      throw OAuth.Error.oauthNotInstalled
    }
    return try await perform(oauth)
  }
}

extension OAuth {
  fileprivate actor Delegate<
    Credentials: BearerAuthenticatingCredentials
  > {

    let upstream: any NetworkingComponent
    var system: any OAuthSystem<Credentials>

    var presentationContext: (any ASWebAuthenticationPresentationContextProviding) = DefaultPresentationContext()

    @Dependency(\.webAuthenticationSession) var webAuthenticationSession

    init(
      upstream: any NetworkingComponent,
      system: some OAuthSystem<Credentials>
    ) {
      self.upstream = upstream
      self.system = system
    }

    func set(
      presentationContext: any ASWebAuthenticationPresentationContextProviding
    ) {
      self.presentationContext = presentationContext
    }
  }
}

extension OAuth.Delegate: AuthenticationDelegate {

  func authorize() async throws -> Credentials {

    let state = try OAuth.generateNewState()
    let codeVerifier = try OAuth.generateNewCodeVerifier()
    let codeChallenge = try OAuth.codeChallengeFor(
      verifier: codeVerifier
    )

    let url = try system.buildAuthorizationURL(
      state: state,
      codeChallenge: codeChallenge
    )

    let callbackURL = try await webAuthenticationSession.start(
      authorizationURL: url,
      presentationContext: UncheckedSendable(presentationContext),
      callbackURLScheme: system.callbackScheme
    )

    let code = try system.validate(callback: callbackURL, state: state)

    return try await system.requestCredentials(
      code: code,
      codeVerifier: codeVerifier,
      using: upstream
    )
  }

  func refresh(
    unauthorized: Credentials,
    from response: HTTPResponseData
  ) async throws -> Credentials {
    throw ErrorMessage(message: "TODO: Refresh")
  }
}

extension OAuth {
  fileprivate actor Proxy<
    Credentials: BearerAuthenticatingCredentials
  >: OAuthProxy {
    typealias Delegate = ThreadSafeAuthenticationDelegate<StreamingAuthenticationDelegate<OAuth.Delegate<Credentials>>>

    let delegate: Delegate

    init(delegate: Delegate) {
      self.delegate = delegate
    }

    func set(presentationContext: any ASWebAuthenticationPresentationContextProviding) async {
      await delegate.delegate.delegate.set(presentationContext: presentationContext)
    }

    func subscribeToCredentialsDidChange(_ credentialsDidChange: (Credentials) async -> Void) async {
      do {
        for try await credentials in await delegate.delegate.credentials {
          await credentialsDidChange(credentials)
        }
      } catch {}
    }

    func signIn() async throws {
      _ = try await delegate.authorize()
    }
  }
}

// MARK: - OAuth Installed Systems

extension OAuth {
  fileprivate struct InstalledSystems: Sendable {
    @Protected static var current = Self()
    private var storage: [ObjectIdentifier: AnySendable] = [:]

    private func get<Credentials: BearerAuthenticatingCredentials>(
      key: Credentials.Type
    ) -> OAuth.Proxy<Credentials>? {
      guard
        let base = self.storage[ObjectIdentifier(key)]?.base,
        let value = base as? OAuth.Proxy<Credentials>
      else { return nil }
      return value
    }

    package static func oauth<Credentials: BearerAuthenticatingCredentials>(
      as credentials: Credentials.Type
    ) -> OAuth.Proxy<Credentials>? {
      Self.current.get(key: Credentials.self)
    }

    package static func set<Credentials: BearerAuthenticatingCredentials>(
      oauth proxy: OAuth.Proxy<Credentials>
    ) {
      Self.current.storage[ObjectIdentifier(Credentials.self)] = AnySendable(proxy)
    }
  }
}
