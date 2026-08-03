import Foundation
import HTTPTypes
import Networking

extension AuthenticationMethod {
  public static let google = AuthenticationMethod(rawValue: "google")
}

extension OAuth.AvailableSystems {
  /// Google OAuth 2.0 for installed/iOS-type clients: PKCE, no client secret, a reverse-DNS custom
  /// redirect scheme captured by `ASWebAuthenticationSession`. Conforms directly to the base
  /// `OAuthSystem` (not `StandardOAuthSystem`) because Google diverges from the standard flow in two
  /// ways handled here: the authorization URL must request offline access + a consent prompt to be
  /// issued a refresh token, and the refresh response omits `refresh_token`, so it is carried forward.
  public struct Google: OAuthSystem {
    public struct Credentials: OAuthCredentials {
      public static let method: AuthenticationMethod = .google
      public let accessToken: String
      public let expiresIn: Int
      public let refreshToken: String
      public let scope: String?
      public let tokenType: String

      public init(
        accessToken: String,
        expiresIn: Int,
        refreshToken: String,
        scope: String?,
        tokenType: String
      ) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.scope = scope
        self.tokenType = tokenType
      }

      public enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case tokenType = "token_type"
      }

      // Google omits `refresh_token` on the refresh response; tolerate it (default "") so the
      // non-optional `OAuthCredentials.refreshToken` contract holds. `mergingRefreshToken(from:)`
      // restores a real value from the prior credentials during a refresh.
      public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken) ?? ""
        scope = try container.decodeIfPresent(String.self, forKey: .scope)
        tokenType = try container.decode(String.self, forKey: .tokenType)
      }

      func mergingRefreshToken(from previous: Credentials) -> Credentials {
        guard refreshToken.isEmpty else { return self }
        return Credentials(
          accessToken: accessToken,
          expiresIn: expiresIn,
          refreshToken: previous.refreshToken,
          scope: scope,
          tokenType: tokenType
        )
      }
    }

    public let clientId: String
    public let redirectURI: String
    public let scope: String?

    public init(clientId: String, redirectURI: String, scope: String?) {
      self.clientId = clientId
      self.redirectURI = redirectURI
      self.scope = scope
    }

    let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    let tokenEndpoint = "https://oauth2.googleapis.com/token"

    public func buildAuthorizationURL(
      state: String,
      codeChallenge: String
    ) throws -> URL {
      guard var components = URLComponents(string: authorizationEndpoint) else {
        throw OAuth.Error.invalidAuthorizationEndpoint(authorizationEndpoint)
      }
      var items = [
        URLQueryItem(name: "client_id", value: clientId),
        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "redirect_uri", value: redirectURI),
        URLQueryItem(name: "state", value: state),
        URLQueryItem(name: "code_challenge", value: codeChallenge),
        URLQueryItem(name: "code_challenge_method", value: "S256"),
        // Required for Google to return a refresh token to an installed app.
        URLQueryItem(name: "access_type", value: "offline"),
        URLQueryItem(name: "prompt", value: "consent"),
      ]
      if let scope {
        items.append(URLQueryItem(name: "scope", value: scope))
      }
      components.queryItems = items
      guard let url = components.url else {
        throw OAuth.Error.invalidAuthorizationURL(components)
      }
      return url
    }

    public func validate(
      callback: URL,
      state expectedState: String
    ) throws -> String {
      let state = try extractValueFrom(callback, forQueryNamed: "state")
      guard state == expectedState else {
        throw OAuth.Error.invalidCallbackURL(callback)
      }
      return try extractValueFrom(callback, forQueryNamed: "code")
    }

    public func requestCredentials(
      code: String,
      codeVerifier: String,
      using upstream: any NetworkingComponent
    ) async throws -> Credentials {
      try await post(
        using: upstream,
        body: """
          grant_type=authorization_code\
          &code=\(code)\
          &redirect_uri=\(redirectURI)\
          &client_id=\(clientId)\
          &code_verifier=\(codeVerifier)
          """
      )
    }

    public func refreshCredentials(
      _ credentials: Credentials,
      using upstream: any NetworkingComponent
    ) async throws -> Credentials {
      let refreshed = try await post(
        using: upstream,
        body: """
          grant_type=refresh_token\
          &refresh_token=\(credentials.refreshToken)\
          &client_id=\(clientId)
          """
      )
      return refreshed.mergingRefreshToken(from: credentials)
    }

    private func post(
      using upstream: any NetworkingComponent,
      body requestBody: String
    ) async throws -> Credentials {
      guard let url = URL(string: tokenEndpoint) else {
        throw OAuth.Error.invalidTokenEndpoint(tokenEndpoint)
      }

      let requestData = requestBody.data(using: .utf8)

      var http = HTTPRequestData(
        method: .post,
        url: url,
        headerFields: [
          .contentType: "application/x-www-form-urlencoded"
        ],
        body: requestData
      )

      if let contentLength = requestData?.count {
        http.headerFields.append(HTTPField(name: .contentLength, value: "\(contentLength)"))
      }

      http.serverMutations = .disabled
      http.redactedBodyFields = OAuth.redactedBodyFields

      return try await upstream.value(http, as: Credentials.self, decoder: JSONDecoder()).body
    }
  }
}

extension OAuthSystem where Self == OAuth.AvailableSystems.Google {
  public static func google(
    clientId: String,
    callback: String,
    scope: String? = nil
  ) -> Self {
    OAuth.AvailableSystems.Google(clientId: clientId, redirectURI: callback, scope: scope)
  }
}

extension NetworkingComponent {
  public func google<ReturnValue: Sendable>(
    perform: @Sendable (any OAuthProxy<OAuth.AvailableSystems.Google.Credentials>) async throws -> ReturnValue
  ) async throws -> ReturnValue {
    try await oauth(of: OAuth.AvailableSystems.Google.Credentials.self, perform: perform)
  }
}
