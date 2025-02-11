import AssertionExtras
import Foundation
import Helpers
import Networking
import TestSupport
import Testing
import XCTestDynamicOverlay

@testable import OAuth

struct StandardOAuthSystemTests: TestableNetwork {

  let stub = StubOAuthSystem(
    authorizationEndpoint: "https://accounts.example.com/authorize",
    tokenEndpoint: "https://accounts.example.com/api/token",
    clientId: "some-client-id",
    redirectURI: "some-redirect-uri://callback",
    scope: "some-scope"
  )

  @Test func test__validate_url() {
    #expect(stub.validate(url: URL(static: "https://example.com")))
    #expect(!stub.validate(url: URL(static: "example.com")))
    #expect(!stub.validate(url: URL(static: "example")))
  }

  @Test func test__build_authorization_url() throws {
    let url = try stub.buildAuthorizationURL(state: "abc123", codeChallenge: "def456")
    #expect(
      url.absoluteString == """
        https://accounts.example.com/authorize\
        ?client_id=some-client-id\
        &response_type=code\
        &redirect_uri=some-redirect-uri://callback\
        &state=abc123\
        &code_challenge=def456\
        &code_challenge_method=S256\
        &scope=some-scope
        """
    )
  }

  @Test func test__validate_callback__given_expected_state() throws {
    let callback = URL(static: "some-redirect-uri://callback?state=abc123&code=xyz987")
    #expect(try stub.validate(callback: callback, state: "abc123") == "xyz987")
  }

  @Test func test__request_credentials() async throws {
    let reporter = TestReporter()

    let expectedCredentials = StubOAuthSystem.Credentials(
      accessToken: "access",
      refreshToken: "refresh"
    )

    let redirectURI = stub.redirectURI
    let clientId = stub.clientId
    let code = "abc123"
    let codeVerifier = "def456"

    try await withTestDependencies {
      $0.oauthSystems = .basic()
    } operation: {
      let network = try TerminalNetworkingComponent()
        .mocked(.ok(body: JSONBody(expectedCredentials))) { request in
          // Check the POST body
          request.prettyPrintedBody
            == "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)&client_id=\(clientId)&code_verifier=\(codeVerifier)"
        }
        // Note that this is not the token endpoint, to simulate an API client
        .server(authority: "api.example.com")
        .reported(by: reporter)

      let receivedCredentials = try await stub.requestCredentials(
        code: code,
        codeVerifier: codeVerifier,
        using: network
      )

      #expect(receivedCredentials == expectedCredentials)

      let requests = await reporter.requests.compactMap(\.url?.absoluteString)
      #expect(requests == [stub.tokenEndpoint])
    }
  }

  @Test func test__refresh_credentials() async throws {
    let reporter = TestReporter()

    let expiredCredentials = StubOAuthSystem.Credentials(
      accessToken: "expired_access",
      refreshToken: "expired_refresh"
    )

    let expectedCredentials = StubOAuthSystem.Credentials(
      accessToken: "updated_access",
      refreshToken: "updated_refresh"
    )

    let clientId = stub.clientId

    try await withTestDependencies {
      $0.oauthSystems = .basic()
    } operation: {
      let network = try TerminalNetworkingComponent()
        .mocked(.ok(body: JSONBody(expectedCredentials))) { request in
          // Check the POST body
          request.prettyPrintedBody
            == "grant_type=refresh_token&refresh_token=\(expiredCredentials.refreshToken)&client_id=\(clientId)"
        }
        // Note that this is not the token endpoint, to simulate an API client
        .server(authority: "api.example.com")
        .reported(by: reporter)

      let receivedCredentials = try await stub.refreshCredentials(expiredCredentials, using: network)

      #expect(receivedCredentials == expectedCredentials)

      let requests = await reporter.requests.compactMap(\.url?.absoluteString)
      #expect(requests == [stub.tokenEndpoint])
    }
  }

  // MARK: - Sad Paths

  @Test func test__given_invalid_endpoint__build_authorization_url__throws_error() throws {
    let stub = StubOAuthSystem(
      authorizationEndpoint: /* invalid URL */ "authorize",
      tokenEndpoint: "https://example.com/api/token",
      clientId: "some-client-id",
      redirectURI: "some-redirect-uri://callback",
      scope: "some-scope"
    )
    #expect(throws: OAuth.Error.self) {
      try stub.buildAuthorizationURL(state: "abc123", codeChallenge: "def456")
    }
  }

  @Test func test__validate_callback_with_invalid_state() throws {
    let callback = URL(static: "some-redirect-uri://callback?state=abc123&code=xyz987")
    #expect(throws: OAuth.Error.invalidCallbackURL(callback)) {
      try stub.validate(callback: callback, state: "def456")
    }
  }

  @Test func test__validate_callback_with_missing_code() throws {
    let callback = URL(static: "some-redirect-uri://callback?state=abc123")
    #expect(throws: ErrorMessage(message: "Missing query parameter 'code': \(callback)")) {
      try stub.validate(callback: callback, state: "abc123")
    }
  }

  @Test func test__given_invalid_endpoint__request_credentials_throws_error() async throws {
    let stub = StubOAuthSystem(
      authorizationEndpoint: "https://accounts.example.com/authorize",
      tokenEndpoint: "api/token",
      clientId: "some-client-id",
      redirectURI: "some-redirect-uri://callback",
      scope: "some-scope"
    )

    await #expect(throws: OAuth.Error.invalidTokenEndpoint("api/token")) {
      try await stub.requestCredentials(
        code: "abc123",
        codeVerifier: "def456",
        using: TerminalNetworkingComponent()
      )
    }
  }
}
