import AuthenticationServices
import ConcurrencyExtras

extension NetworkingComponent {

  public func authenticated(
    oauth: any OAuthSystem
  ) -> some NetworkingComponent {
    let delegate = OAuth.Delegate(system: oauth)
    return withNetworkEnvironment {
      $0.oauth = delegate
    } operation: {
      authenticated(with: delegate)
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
}

extension OAuth {
  fileprivate actor Delegate: OAuthProxy, NetworkEnvironmentKey, AuthenticationDelegate {
    var system: any OAuthSystem

    var presentationContext: (any ASWebAuthenticationPresentationContextProviding) = DefaultPresentationContext()

    init(system: any OAuthSystem) {
      self.system = system
    }

    func set(
      presentationContext: any ASWebAuthenticationPresentationContextProviding
    ) {
      self.presentationContext = presentationContext
    }

    func authorize(
      server newServer: String? = nil,
      scope newScope: String? = nil
    ) async throws {
      if let newServer, newServer.isNotEmpty {
        system.authorizationServer = newServer
      }

      if let newScope, newScope.isNotEmpty {
        system.scope = newScope
      }

      // Construct a URL
      guard var components = URLComponents(string: system.authorizationServer) else {
        throw Error.invalidAuthorizationService(system.authorizationServer)
      }

      components.queryItems = [
        URLQueryItem(name: "client_id", value: system.clientId)
      ]

      if let scope = system.scope {
        components.queryItems = [
          URLQueryItem(name: "scope", value: scope)
        ]
      }

      guard let url = components.url else {
        throw Error.invalidAuthorizationURL(components)
      }

      //      let callbackURL: URL
      if #available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *) {
        let callbackURL = try await ASWebAuthenticationSession.start(
          url: url,
          presentationContext: UncheckedSendable(presentationContext),
          callback: system.callback
        )
      } else {

      }
    }

    func fetch(
      for request: HTTPRequestData
    ) async throws -> BearerCredentials {
      throw "TODO"
    }

    func refresh(
      unauthorized: BearerCredentials,
      from response: HTTPResponseData
    ) async throws -> BearerCredentials {
      throw "TODO"
    }
  }
}

extension NetworkEnvironmentValues {
  fileprivate var oauth: OAuth.Delegate? {
    get { self[OAuth.Delegate.self] }
    set { self[OAuth.Delegate.self] = newValue }
  }
}
