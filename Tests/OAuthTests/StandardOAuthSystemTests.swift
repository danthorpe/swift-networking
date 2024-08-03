import AssertionExtras
import Foundation
import Helpers
import Networking
import TestSupport
import XCTest
import XCTestDynamicOverlay

@testable import OAuth

final class StandardOAuthSystemTests: OAuthTestCase {

  func test__validate_url() {
    XCTAssertTrue(stub.validate(url: URL(static: "https://example.com")))
    XCTAssertFalse(stub.validate(url: URL(static: "example.com")))
    XCTAssertFalse(stub.validate(url: URL(static: "example")))
  }

  func test__build_authorization_url() throws {
    let url = try stub.buildAuthorizationURL(state: "abc123", codeChallenge: "def456")
    XCTAssertEqual(
      url.absoluteString,
      """
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

  func test__validate_callback__given_expected_state() throws {
    let callback = URL(static: "some-redirect-uri://callback?state=abc123&code=xyz987")
    XCTAssertEqual(try stub.validate(callback: callback, state: "abc123"), "xyz987")
  }

  func test__request_credentials() async throws {
    let reporter = TestReporter()

    let expectedCredentials = StubOAuthSystem.Credentials(
      accessToken: "access",
      refreshToken: "refresh"
    )

    let redirectURI = stub.redirectURI
    let clientId = stub.clientId
    let code = "abc123"
    let codeVerifier = "def456"

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

    XCTAssertEqual(receivedCredentials, expectedCredentials)

    let requests = await reporter.requests.compactMap(\.url?.absoluteString)
    XCTAssertEqual(requests, [stub.tokenEndpoint])
  }

  func test__refresh_credentials() async throws {
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

    XCTAssertEqual(receivedCredentials, expectedCredentials)

    let requests = await reporter.requests.compactMap(\.url?.absoluteString)
    XCTAssertEqual(requests, [stub.tokenEndpoint])

  }

  // MARK: - Sad Paths

  func test__given_invalid_endpoint__build_authorization_url__throws_error() throws {
    stub = StubOAuthSystem(
      authorizationEndpoint: /* invalid URL */ "authorize",
      tokenEndpoint: "https://example.com/api/token",
      clientId: "some-client-id",
      redirectURI: "some-redirect-uri://callback",
      scope: "some-scope"
    )
    XCTAssertThrowsError(try stub.buildAuthorizationURL(state: "abc123", codeChallenge: "def456"))
  }

  func test__validate_callback_with_invalid_state() throws {
    let callback = URL(static: "some-redirect-uri://callback?state=abc123&code=xyz987")
    XCTAssertThrowsError(try stub.validate(callback: callback, state: "def456")) { error in
      XCTAssertTrue(_isEqual(error, OAuth.Error.invalidCallbackURL(callback)))
    }
  }

  func test__validate_callback_with_missing_code() throws {
    let callback = URL(static: "some-redirect-uri://callback?state=abc123")
    XCTAssertThrowsError(try stub.validate(callback: callback, state: "abc123"))
  }

  func test__given_invalid_endpoint__request_credentials_throws_error() async throws {
    stub = StubOAuthSystem(
      authorizationEndpoint: "https://accounts.example.com/authorize",
      tokenEndpoint: "api/token",
      clientId: "some-client-id",
      redirectURI: "some-redirect-uri://callback",
      scope: "some-scope"
    )

    await XCTAssertThrowsError(
      try await stub.requestCredentials(
        code: "abc123",
        codeVerifier: "def456",
        using: TerminalNetworkingComponent()
      ),
      matches: OAuth.Error.invalidTokenEndpoint("api/token")
    )
  }
}
