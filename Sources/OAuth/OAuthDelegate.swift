import AuthenticationServices
import ConcurrencyExtras
import Dependencies
import Helpers
import Networking
import Protected

extension OAuth {
  actor Delegate<Credentials: OAuthCredentials> {

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
      state: state,
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
    try await system.refreshCredentials(
      unauthorized,
      using: upstream
    )
  }
}
