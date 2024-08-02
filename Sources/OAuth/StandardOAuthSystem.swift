import Foundation
import HTTPTypes
import Networking

public protocol StandardOAuthSystem<Credentials>: OAuthSystem {
  var authorizationEndpoint: String { get }
  var tokenEndpoint: String { get }
}

extension StandardOAuthSystem {

  public func buildAuthorizationURL(
    state: String,
    codeChallenge: String
  ) throws -> URL {
    var components = try authorizationComponents()

    components.queryItems = [
      URLQueryItem(name: "client_id", value: clientId),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "redirect_uri", value: redirectURI),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
    ]

    if let scope {
      components.queryItems.append(
        URLQueryItem(name: "scope", value: scope)
      )
    }

    guard let url = components.url, validate(url: url) else {
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
    try await post(
      using: upstream,
      body: """
        grant_type=refresh_token\
        &refresh_token=\(credentials.refreshToken)\
        &client_id=\(clientId)
        """
    )
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

    return try await upstream.value(http, as: Credentials.self, decoder: JSONDecoder()).body
  }

  func authorizationComponents() throws -> URLComponents {
    guard
      let url = URL(string: authorizationEndpoint),
      validate(url: url),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      throw OAuth.Error.invalidAuthorizationEndpoint(authorizationEndpoint)
    }
    return components
  }

  func validate(url: URL) -> Bool {
    false == url.scheme.isEmptyOrNil && false == url.host().isEmptyOrNil
  }
}
