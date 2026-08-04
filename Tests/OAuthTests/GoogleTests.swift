import AssertionExtras
import Foundation
import Helpers
import Networking
import TestSupport
import Testing
import XCTestDynamicOverlay

@testable import OAuth

@Suite
struct GoogleTests: TestableNetwork {

  let system = OAuth.AvailableSystems.Google(
    clientId: "cid.apps.googleusercontent.com",
    redirectURI: "com.googleusercontent.apps.cid:/oauth2redirect",
    scope: "https://www.googleapis.com/auth/photoslibrary.appendonly"
  )

  // MARK: - Endpoints

  @Test func test__google_endpoints() {
    #expect(system.authorizationEndpoint == "https://accounts.google.com/o/oauth2/v2/auth")
    #expect(system.tokenEndpoint == "https://oauth2.googleapis.com/token")
  }

  // MARK: - Authorization URL

  @Test func test__authorization_url_carries_offline_consent_and_pkce() throws {
    let url = try system.buildAuthorizationURL(state: "STATE", codeChallenge: "CHAL")
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
    #expect(url.host == "accounts.google.com")
    #expect(value("client_id") == "cid.apps.googleusercontent.com")
    #expect(value("redirect_uri") == "com.googleusercontent.apps.cid:/oauth2redirect")
    #expect(value("response_type") == "code")
    #expect(value("state") == "STATE")
    #expect(value("code_challenge") == "CHAL")
    #expect(value("code_challenge_method") == "S256")
    #expect(value("access_type") == "offline")
    #expect(value("prompt") == "consent")
    #expect(value("scope") == "https://www.googleapis.com/auth/photoslibrary.appendonly")
  }

  // MARK: - Callback validation

  @Test func test__validate_callback__given_expected_state() throws {
    let callback = URL(static: "com.googleusercontent.apps.cid:/oauth2redirect?state=STATE&code=AUTHCODE")
    #expect(try system.validate(callback: callback, state: "STATE") == "AUTHCODE")
  }

  @Test func test__validate_callback__with_invalid_state() throws {
    let callback = URL(static: "com.googleusercontent.apps.cid:/oauth2redirect?state=OTHER&code=AUTHCODE")
    #expect(throws: OAuth.Error.invalidCallbackURL(callback)) {
      try system.validate(callback: callback, state: "STATE")
    }
  }

  // MARK: - Credentials decoding

  @Test func test__credentials_decode_tolerates_missing_refresh_token() throws {
    let json = #"{"access_token":"a","expires_in":3600,"scope":"s","token_type":"Bearer"}"#
    let creds = try JSONDecoder().decode(
      OAuth.AvailableSystems.Google.Credentials.self, from: Data(json.utf8))
    #expect(creds.refreshToken == "")
    #expect(creds.accessToken == "a")
    #expect(creds.expiresIn == 3600)
  }

  @Test func test__refresh_merge_carries_prior_token_when_response_omits_it() {
    let prior = OAuth.AvailableSystems.Google.Credentials(
      accessToken: "old", expiresIn: 3600, refreshToken: "REFRESH", scope: "s", tokenType: "Bearer")
    let responseWithoutRefresh = OAuth.AvailableSystems.Google.Credentials(
      accessToken: "new", expiresIn: 3600, refreshToken: "", scope: "s", tokenType: "Bearer")
    let merged = responseWithoutRefresh.mergingRefreshToken(from: prior)
    #expect(merged.refreshToken == "REFRESH")
    #expect(merged.accessToken == "new")
  }

  @Test func test__refresh_merge_keeps_response_token_when_present() {
    let prior = OAuth.AvailableSystems.Google.Credentials(
      accessToken: "old", expiresIn: 3600, refreshToken: "OLD", scope: "s", tokenType: "Bearer")
    let response = OAuth.AvailableSystems.Google.Credentials(
      accessToken: "new", expiresIn: 3600, refreshToken: "NEW", scope: "s", tokenType: "Bearer")
    #expect(response.mergingRefreshToken(from: prior).refreshToken == "NEW")
  }

  // MARK: - Token requests (mocked network)

  @Test func test__request_credentials() async throws {
    let reporter = TestReporter()
    let code = "abc123"
    let codeVerifier = "def456"
    let redirectURI = system.redirectURI
    let clientId = system.clientId

    let responseBody = GoogleTokenResponse(
      access_token: "access", expires_in: 3600, refresh_token: "refresh",
      scope: "s", token_type: "Bearer")

    try await withTestDependencies {
      $0.oauthSystems = .basic()
    } operation: {
      let network = try TerminalNetworkingComponent()
        .mocked(.ok(body: JSONBody(responseBody))) { request in
          String(decoding: request.body ?? Data(), as: UTF8.self)
            == "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)&client_id=\(clientId)&code_verifier=\(codeVerifier)"
        }
        .server(authority: "www.googleapis.com")
        .reported(by: reporter)

      let credentials = try await system.requestCredentials(
        code: code, codeVerifier: codeVerifier, using: network)

      #expect(credentials.accessToken == "access")
      #expect(credentials.refreshToken == "refresh")

      let requests = await reporter.requests.compactMap(\.url?.absoluteString)
      #expect(requests == [system.tokenEndpoint])
    }
  }

  @Test func test__refresh_credentials_carries_prior_refresh_token() async throws {
    let clientId = system.clientId
    let expired = OAuth.AvailableSystems.Google.Credentials(
      accessToken: "expired_access", expiresIn: 0, refreshToken: "the_refresh_token",
      scope: "s", tokenType: "Bearer")

    // Google's refresh response omits refresh_token.
    let responseBody = GoogleRefreshResponse(
      access_token: "updated_access", expires_in: 3600, scope: "s", token_type: "Bearer")

    try await withTestDependencies {
      $0.oauthSystems = .basic()
    } operation: {
      let network = try TerminalNetworkingComponent()
        .mocked(.ok(body: JSONBody(responseBody))) { request in
          String(decoding: request.body ?? Data(), as: UTF8.self)
            == "grant_type=refresh_token&refresh_token=\(expired.refreshToken)&client_id=\(clientId)"
        }
        .server(authority: "www.googleapis.com")

      let refreshed = try await system.refreshCredentials(expired, using: network)

      #expect(refreshed.accessToken == "updated_access")
      #expect(refreshed.refreshToken == "the_refresh_token")  // carried forward
    }
  }

  // MARK: - Convenience installation

  @Test func test__create_google_convenience() async throws {
    try await withTestDependencies {
      $0.oauthSystems = .basic()
    } operation: {
      let network = TerminalNetworkingComponent()
        .authenticated(
          oauth: .google(
            clientId: "some-client-id",
            callback: "com.googleusercontent.apps.some:/oauth2redirect",
            scope: "some-scope"))

      try await network.google { _ in
        // no-op — proves the .google factory + accessor compile and install.
      }
    }
  }
}

// Full Google token response (initial exchange).
private struct GoogleTokenResponse: Encodable {
  let access_token: String
  let expires_in: Int
  let refresh_token: String
  let scope: String
  let token_type: String
}

// Refresh response — Google omits refresh_token here.
private struct GoogleRefreshResponse: Encodable {
  let access_token: String
  let expires_in: Int
  let scope: String
  let token_type: String
}
