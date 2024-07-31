import Foundation

extension OAuth.AvailableSystems {
  public struct Spotify: Sendable {
    public struct Credentials: Decodable, Sendable {
      public enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case tokenType = "token_type"
      }
      public let accessToken: String
      public let expiresIn: Int
      public let refreshToken: String
      public let scope: String?
      public let tokenType: String
    }
    public let clientId: String
    public let callback: String
    public let scope: String?
  }
}

extension OAuth.AvailableSystems.Spotify: OAuthSystem {

  public func buildAuthorizationURL(
    state: String,
    codeChallenge: String
  ) throws -> URL {
    guard var components = URLComponents(string: "https://accounts.spotify.com/authorize") else {
      throw OAuth.Error.invalidAuthorizationService
    }

    components.queryItems = [
      URLQueryItem(name: "client_id", value: clientId),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "redirect_uri", value: callback),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
    ]

    if let scope {
      components.queryItems.append(
        URLQueryItem(name: "scope", value: scope)
      )
    }
    guard let url = components.url else {
      throw OAuth.Error.invalidAuthorizationURL(components)
    }
    return url
  }

  public func validate(callback: URL, state expectedState: String) throws -> String {
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

    let requestBody =
      "grant_type=authorization_code" + "&code=\(code)" + "&redirect_uri=\(callback)" + "&client_id=\(clientId)"
      + "&code_verifier=\(codeVerifier)"

    let requestData = requestBody.data(using: .utf8)

    var http = HTTPRequestData(
      method: .post,
      scheme: "https",
      authority: "accounts.spotify.com",
      path: "/api/token",
      headerFields: [
        .contentType: "application/x-www-form-urlencoded"
      ],
      body: requestData
    )

    if let contentLength = requestData?.count {
      http.headerFields.append([.contentLength: "\(contentLength)"])
    }

    http.serverMutations = .disabled

    return try await upstream.value(http, as: Credentials.self, decoder: JSONDecoder()).body
  }
}

extension AuthenticationMethod {
  public static let spotify = AuthenticationMethod(rawValue: "spotify")
}

extension OAuth.AvailableSystems.Spotify.Credentials: BearerAuthenticatingCredentials {
  public static let method: AuthenticationMethod = .spotify
  public func apply(to request: HTTPRequestData) -> HTTPRequestData {
    apply(token: accessToken, to: request)
  }
}

extension OAuthSystem where Self == OAuth.AvailableSystems.Spotify {
  public static func spotify(
    clientId: String,
    callback: String,
    scope: String? = nil
  ) -> Self {
    OAuth.AvailableSystems.Spotify(clientId: clientId, callback: callback, scope: scope)
  }
}

extension NetworkingComponent {
  public func spotify<ReturnValue>(
    perform: (any OAuthProxy<OAuth.AvailableSystems.Spotify.Credentials>) async throws -> ReturnValue
  ) async throws -> ReturnValue {
    try await oauth(of: OAuth.AvailableSystems.Spotify.Credentials.self, perform: perform)
  }
}
