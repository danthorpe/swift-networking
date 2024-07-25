import AuthenticationServices
import ConcurrencyExtras
import Helpers
import Protected

extension NetworkingComponent {

  public func authenticated<Credentials: BearerAuthenticatingCredentials>(
    oauth: some OAuthSystem<Credentials>,
    credentials: Credentials? = nil,
    didUpdateCredentials: @escaping @Sendable (Credentials) -> Void = { _ in }
  ) -> some NetworkingComponent {
    let delegate = OAuth.Delegate<Credentials>(
      upstream: self,
      system: oauth,
      credentials: credentials,
      didUpdateCredentials: didUpdateCredentials
    )
    OAuth.InstalledSystems.set(oauth: delegate)
    return authenticated(
      with: HeaderBasedAuthentication(delegate: delegate)
    )
  }

  public func oauth<ReturnValue, Credentials: BearerAuthenticatingCredentials>(
    of credentialsType: Credentials.Type,
    perform: (any OAuthProxy<Credentials>) async throws -> ReturnValue
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
  >: OAuthProxy, AuthenticationDelegate {

    let upstream: any NetworkingComponent
    var system: any OAuthSystem<Credentials>

    var presentationContext: (any ASWebAuthenticationPresentationContextProviding) = DefaultPresentationContext()
    var didUpdateCredentials: (Credentials) -> Void = { _ in }
    var credentials: Credentials? {
      didSet {
        if let credentials { didUpdateCredentials(credentials) }
      }
    }

    init(
      upstream: any NetworkingComponent,
      system: some OAuthSystem<Credentials>,
      credentials: Credentials? = nil,
      didUpdateCredentials: @escaping (Credentials) -> Void = { _ in }
    ) {
      self.upstream = upstream
      self.system = system
      self.credentials = credentials
      self.didUpdateCredentials = didUpdateCredentials
    }

    func set(credentials: Credentials) {
      self.credentials = credentials
    }

    func set(didUpdateCredentials: @escaping @Sendable (Credentials) -> Void) {
      self.didUpdateCredentials = didUpdateCredentials
    }

    func set(
      presentationContext: any ASWebAuthenticationPresentationContextProviding
    ) {
      self.presentationContext = presentationContext
    }

    func authorize() async throws {

      let state = try OAuth.generateNewState()
      let codeVerifier = try OAuth.generateNewCodeVerifier()
      let codeChallenge = try OAuth.codeChallengeFor(
        verifier: codeVerifier
      )

      let url = try system.buildAuthorizationURL(
        state: state,
        codeChallenge: codeChallenge
      )

      let callbackURL = try await ASWebAuthenticationSession.start(
        url: url,
        presentationContext: UncheckedSendable(presentationContext),
        callbackURLScheme: system.callbackScheme
      )

      let code = try system.validate(callback: callbackURL, state: state)

      self.credentials = try await system.requestCredentials(
        code: code,
        codeVerifier: codeVerifier,
        using: upstream
      )
    }

    func fetch(
      for request: HTTPRequestData
    ) async throws -> Credentials {
      if let credentials {
        return credentials
      }
      try await authorize()
      guard let credentials else {
        throw ErrorMessage(message: "Failed to fetch credentials")
      }
      return credentials
    }

    func refresh(
      unauthorized: Credentials,
      from response: HTTPResponseData
    ) async throws -> Credentials {
      throw ErrorMessage(message: "TODO: Refresh")
    }
  }
}

extension OAuth {
  fileprivate struct InstalledSystems: Sendable {
    @Protected static var current = Self()
    private var storage: [ObjectIdentifier: AnySendable] = [:]

    private subscript<Credentials: BearerAuthenticatingCredentials>(
      key: Credentials.Type
    ) -> OAuth.Delegate<Credentials>? {
      get {
        guard
          let base = self.storage[ObjectIdentifier(key)]?.base,
          let value = base as? OAuth.Delegate<Credentials>
        else { return nil }
        return value
      }
      set {
        self.storage[ObjectIdentifier(key)] = AnySendable(newValue)
      }
    }

    static func oauth<Credentials: BearerAuthenticatingCredentials>(
      as credentials: Credentials.Type
    ) -> OAuth.Delegate<Credentials>? {
      Self.current[Credentials.self]
    }

    static func set<Credentials: BearerAuthenticatingCredentials>(
      oauth delegate: some OAuth.Delegate<Credentials>
    ) {
      Self.current[Credentials.self] = delegate
    }
  }
}
