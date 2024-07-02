import AuthenticationServices
import Foundation

// MARK: - Public API

extension NetworkingComponent {

  /// Install OAuth 2.1 based Authentication
  /// - Parameters:
  ///   - clientId: The identifier provided by the authentication service for this client.
  ///   - clientSecret: A ``OAuthClientSecret`` value, which defaults to use the PKCE extension
  ///   - redirectURL: The redirect URL registered with the authentication service.
  /// - Returns: some ``NetworkingComponent``
  @available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *)
  public func authenticated(
    oauthService service: String,
    clientId: String,
    clientSecret: OAuth.ClientSecret = .pkce,
    callback: ASWebAuthenticationSession.Callback,
    scope: String? = nil
  ) -> some NetworkingComponent {
    let delegate = OAuth.Delegate(
      clientId: clientId,
      clientSecret: clientSecret,
      callback: callback,
      scope: scope,
      service: service
    )
    return withNetworkEnvironment {
      $0.oauth = delegate
    } operation: {
      authenticated(with: delegate)
        .server(authenticationMethod: .bearer)
    }
  }

  //  public func authenticated(
  //    oauthService service: String,
  //    clientId: String,
  //    clientSecret: OAuth.ClientSecret = .pkce,
  //    redirect: String,
  //    scope: String
  //  ) -> some NetworkingComponent {
  //    self
  //  }

  public func authorizeUsingOAuth(
    authorize server: String? = nil,
    scope: String? = nil
  ) async throws {
    if #available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *) {
      @NetworkEnvironment(\.oauth) var oauth
      guard let oauth else {
        throw OAuth.Error.oauthNotInstalled
      }
      try await oauth.authorize(service: server, scope: scope)
    }
  }
}

public enum OAuth { /* Namespace */  }

extension OAuth {
  public enum ClientSecret: Sendable {
    case secret(String)
    case pkce
  }

  public enum Error: Swift.Error, Equatable {
    case oauthNotInstalled
    case invalidAuthorizationService(String)
    case invalidAuthorizationURL(URLComponents)
    //    case webAuthenticationSessionError(any Swift.Error)
  }
}

// MARK: - Implementation Details

extension OAuth {

  @available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *)
  actor Delegate: @unchecked Sendable, AuthenticationDelegate, NetworkEnvironmentKey {

    let clientId: String
    let clientSecret: ClientSecret
    var callback: ASWebAuthenticationSession.Callback
    var scope: String?
    var service: String

    init(
      clientId: String,
      clientSecret: ClientSecret,
      callback: ASWebAuthenticationSession.Callback,
      scope: String?,
      service: String
    ) {
      self.clientId = clientId
      self.clientSecret = clientSecret
      self.callback = callback
      self.scope = scope
      self.service = service
    }

    func authorize(service newService: String?, scope newScopes: String?) async throws {

      // Update the service & scopes
      service = newService ?? service
      scope = newScopes ?? scope

      // Construct a URL
      guard var components = URLComponents(string: service) else {
        throw Error.invalidAuthorizationService(service)
      }

      components.queryItems = [
        //        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "client_id", value: clientId)
        //        URLQueryItem(name: "redirect_uri", value: redirect),
        //        URLQueryItem(name: "scope", value: scope)
      ]

      guard let url = components.url else {
        throw Error.invalidAuthorizationURL(components)
      }

      let callbackURL = try await ASWebAuthenticationSession.start(
        url: url,
        callback: callback
      )

      throw "TODO: start OAuth Flow"
    }

    func fetch(for request: HTTPRequestData) async throws -> BearerCredentials {
      throw "TODO"
    }

    func refresh(unauthorized: BearerCredentials, from response: HTTPResponseData) async throws -> BearerCredentials {
      throw "TODO"
    }
  }
}

extension NetworkEnvironmentValues {
  @available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *)
  var oauth: OAuth.Delegate? {
    get { self[OAuth.Delegate.self] }
    set { self[OAuth.Delegate.self] = newValue }
  }
}

// MARK: - Requests etc

// MARK: - Temporary

extension String: Error {}

extension ASWebAuthenticationSession {

  @available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *)
  static func start(url: URL, callback: Callback) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      let session = ASWebAuthenticationSession(url: url, callback: callback) { url, error in
        guard let url else {
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(throwing: "TODO: ASWebAuthentication returned with missing URL and no Error")
          }
          return
        }
        continuation.resume(returning: url)
      }
      guard session.start() else {
        continuation.resume(throwing: "TODO: Failed to start ASWebAuthentication Session")
        return
      }
    }
  }
}
