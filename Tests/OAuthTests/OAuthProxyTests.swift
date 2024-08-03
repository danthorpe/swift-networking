import AssertionExtras
import Dependencies
import Foundation
import Helpers
import Networking
import TestSupport
import XCTest
import XCTestDynamicOverlay

@testable import OAuth

final class OAuthProxyTests: OAuthTestCase {

  func test__proxy() async throws {

    let existingCredentials = StubOAuthSystem.Credentials(
      accessToken: "existing_access",
      refreshToken: "existing_refresh"
    )

    let expectedCredentials = StubOAuthSystem.Credentials(
      accessToken: "access",
      refreshToken: "refresh"
    )

    let code = "abc123"

    try await withTestDependencies {
      $0.webAuthenticationSession = WebAuthenticationSessionClient { [redirect = stub.redirectURI] state, _, _, _ in
        URL(string: "\(redirect)?state=\(state)&code=\(code)")!
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
      XCTAssertNotNil(presentationContext)

      // Set credentials
      await proxy.set(credentials: existingCredentials)
      var state = await threadSafe.state
      XCTAssertEqual(state, .authorized(existingCredentials))

      // Sign Out
      await proxy.signOut()
      state = await threadSafe.state
      XCTAssertEqual(state, .idle)

      let exp = expectation(description: "Credentials did change")

      // Subscribe to credential updates
      Task {
        await proxy.subscribeToCredentialsDidChange { credentials in
          XCTAssertEqual(credentials, expectedCredentials)
          exp.fulfill()
        }
      }

      // Sign In
      try await proxy.signIn()

      await fulfillment(of: [exp])
    }
  }
}
