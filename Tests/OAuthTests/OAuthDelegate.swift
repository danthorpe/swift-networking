import AssertionExtras
import Dependencies
import Foundation
import Helpers
import Networking
import TestSupport
import XCTest
import XCTestDynamicOverlay

@testable import OAuth

final class OAuthDelegateTests: OAuthTestCase {

  func test__authentication_delegate__fetches_credentials() async throws {
    let reporter = TestReporter()
    let code = "abc123"
    try await withTestDependencies {
      $0.webAuthenticationSession = WebAuthenticationSessionClient { [redirect = stub.redirectURI] state, _, _, _ in
        URL(string: "\(redirect)?state=\(state)&code=\(code)")!
      }
    } operation: {

      let credentials = StubOAuthSystem.Credentials(
        accessToken: "access-token",
        refreshToken: "refresh-token"
      )

      let resource = HTTPRequestData(path: "/protected-resource")

      let network = TerminalNetworkingComponent()
        .mocked(.ok()) { request in
          request.headerFields[.authorization] == "Bearer \(credentials.accessToken)"
        }
        .reported(by: reporter)
        .server(prefixPath: "v1")
        .server(authenticationMethod: .stub)
        .authenticated(oauth: stub)

    }
  }
}
