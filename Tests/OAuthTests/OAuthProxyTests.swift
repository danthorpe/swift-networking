import AssertionExtras
import Dependencies
import Foundation
import Helpers
import Networking
import TestSupport
import Testing
import XCTestDynamicOverlay

@testable import OAuth

@Suite
struct OAuthProxyTests: TestableNetwork {

  @Test func test__proxy() async throws {

    let existingCredentials = StubOAuthSystem.Credentials(
      accessToken: "existing_access",
      refreshToken: "existing_refresh"
    )

    let expectedCredentials = StubOAuthSystem.Credentials(
      accessToken: "access",
      refreshToken: "refresh"
    )

    let stub = StubOAuthSystem(
      authorizationEndpoint: "https://accounts.example.com/authorize",
      tokenEndpoint: "https://accounts.example.com/api/token",
      clientId: "some-client-id",
      redirectURI: "some-redirect-uri://callback",
      scope: "some-scope"
    )

    let code = "abc123"

    try await withTestDependencies {
      $0.webAuthenticationSession = WebAuthenticationSessionClient { state, _, _, _ in
        URL(string: "\(stub.redirectURI)?state=\(state)&code=\(code)")!
      }
    } operation: {

      let network = try TerminalNetworkingComponent()
        .mocked(.ok(body: JSONBody(expectedCredentials))) { _ in true }
        // Note that this is not the token endpoint, to simulate an API client
        .server(authority: "api.example.com")

      let oauthDelegate = OAuth.Delegate(upstream: network, system: stub)
      let stream = StreamingAuthenticationDelegate(delegate: oauthDelegate)
      let threadSafe = ThreadSafeAuthenticationDelegate(delegate: stream)
      let proxy = OAuth.Proxy(delegate: threadSafe)

      // Set presentation context
      await proxy.set(presentationContext: DefaultPresentationContext())
      let presentationContext = await oauthDelegate.presentationContext
      #expect(presentationContext != nil)

      // Set credentials
      await proxy.set(credentials: existingCredentials)
      var state = await threadSafe.state
      #expect(state == .authorized(existingCredentials))

      // Sign Out
      await proxy.signOut()
      state = await threadSafe.state
      #expect(state == .idle)

      // Subscribe to credential updates
      Task {
        await confirmation { expectedCredentialsDidChange in
          await proxy.subscribeToCredentialsDidChange { credentials in
            #expect(credentials == expectedCredentials)
            expectedCredentialsDidChange()
          }
        }
      }

      // Sign In
      try await proxy.signIn()
    }
  }
}
