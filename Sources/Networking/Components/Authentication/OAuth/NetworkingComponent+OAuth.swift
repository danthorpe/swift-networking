import AuthenticationServices
import ConcurrencyExtras
import Helpers

extension NetworkingComponent {

  public func authenticated(
    oauth: any OAuthSystem
  ) -> some NetworkingComponent {
    let delegate = OAuth.Delegate(
      upstream: self,
      system: oauth
    )
    return withNetworkEnvironment {
      $0.oauth = delegate
    } operation: {
      authenticated(with: BearerAuthentication(delegate: delegate))
        .server(authenticationMethod: .bearer)
    }
  }

  public func oauth<ReturnValue>(
    perform: (any OAuthProxy) async throws -> ReturnValue
  ) async throws -> ReturnValue {
    @NetworkEnvironment(\.oauth) var oauth
    guard let oauth else {
      throw OAuth.Error.oauthNotInstalled
    }
    return try await perform(oauth)
  }

  public func oauth<System: OAuthSystem, ReturnValue>(
    perform: (System) async throws -> ReturnValue
  ) async throws -> ReturnValue {
    @NetworkEnvironment(\.oauth) var oauth
    guard let oauth, let system = oauth as? System else {
      throw OAuth.Error.oauthNotInstalled
    }
    return try await perform(system)
  }
}

extension OAuth {
  fileprivate actor Delegate: OAuthProxy, NetworkEnvironmentKey, AuthenticationDelegate {
    let upstream: any NetworkingComponent
    var system: any OAuthSystem

    var presentationContext: (any ASWebAuthenticationPresentationContextProviding) = DefaultPresentationContext()

    init(upstream: any NetworkingComponent, system: any OAuthSystem) {
      self.upstream = upstream
      self.system = system
    }

    func set(
      presentationContext: any ASWebAuthenticationPresentationContextProviding
    ) {
      self.presentationContext = presentationContext
    }

    func authorize() async throws {

      let url = try system.authorizationURL()

      let callbackURL = try await ASWebAuthenticationSession.start(
        url: url,
        presentationContext: UncheckedSendable(presentationContext),
        callbackURLScheme: system.callbackScheme
      )

      let code = try system.validate(callback: callbackURL)

      try await system.requestTokenExchange(
        code: code,
        using: upstream
      )
    }

    func fetch(
      for request: HTTPRequestData
    ) async throws -> BearerCredentials {
      if nil != system.credentials {
        try await authorize()
      }
      return try system.getBearerCredentials()
    }

    func refresh(
      unauthorized: BearerCredentials,
      from response: HTTPResponseData
    ) async throws -> BearerCredentials {
      throw ErrorMessage(message: "TODO: Refresh")
    }
  }
}

extension NetworkEnvironmentValues {
  fileprivate var oauth: OAuth.Delegate? {
    get { self[OAuth.Delegate.self] }
    set { self[OAuth.Delegate.self] = newValue }
  }
}
