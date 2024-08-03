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

      let network = TerminalNetworkingComponent()
        .mocked { request in
          if request.headerFields[.authorization] == "Bearer \(credentials.accessToken)" {
            return .ok()
          } else if request.path == "/v1/protected-resource" {
            return .status(.unauthorized)
          } else if request.path == "/api/token" {
            return try .ok(body: JSONBody(credentials))
          } else {
            print(request.debugDescription)
            return nil
          }
        }
        .reported(by: reporter)
        .server(prefixPath: "v1")
        .server(authenticationMethod: .stub)
        .authenticated(oauth: stub)

      // Make a request to protected resource
      var request = HTTPRequestData(path: "/protected-resource")
      request.authenticationMethod = .stub
      try await network.data(request)

      let sentRequests = await reporter.requests

      XCTAssertEqual(
        sentRequests.map(\.path),
        [
          "/api/token",
          "/v1/protected-resource",
        ])
    }
  }

  func test__given_already_has_credentials__authentication_delegate_does_not_fetch_credentials() async throws {
    let reporter = TestReporter()

    let credentials = StubOAuthSystem.Credentials(
      accessToken: "access-token",
      refreshToken: "refresh-token"
    )

    let network = TerminalNetworkingComponent()
      .mocked { request in
        if request.headerFields[.authorization] == "Bearer \(credentials.accessToken)" {
          return .ok()
        } else if request.path == "/v1/protected-resource" {
          return .status(.unauthorized)
        } else if request.path == "/api/token" {
          return try .ok(body: JSONBody(credentials))
        } else {
          print(request.debugDescription)
          return nil
        }
      }
      .reported(by: reporter)
      .server(prefixPath: "v1")
      .server(authenticationMethod: .stub)
      .authenticated(oauth: stub)

    // Provide valid credentials
    try await network.stubOAuthSystem {
      await $0.set(credentials: credentials)
    }

    // Make a request to protected resource
    var request = HTTPRequestData(path: "/protected-resource")
    request.authenticationMethod = .stub
    try await network.data(request)

    let sentRequests = await reporter.requests

    XCTAssertEqual(
      sentRequests.map(\.path),
      [
        "/v1/protected-resource"
      ])
  }

  func test__given_already_has_expired_credentials__authentication_delegate_refreshes_credentials() async throws {
    let reporter = TestReporter()
    let code = "abc123"
    try await withTestDependencies {
      $0.webAuthenticationSession = WebAuthenticationSessionClient { [redirect = stub.redirectURI] state, _, _, _ in
        URL(string: "\(redirect)?state=\(state)&code=\(code)")!
      }
    } operation: {

      let expired = StubOAuthSystem.Credentials(
        accessToken: "expired-access-token",
        refreshToken: "refresh-token"
      )

      let credentials = StubOAuthSystem.Credentials(
        accessToken: "valid-access-token",
        refreshToken: "refresh-token"
      )

      @Sendable func checkForRefresh(in request: HTTPRequestData) -> Bool {
        request.prettyPrintedBody.contains(
          "grant_type=refresh_token&refresh_token=\(expired.refreshToken)"
        )
      }

      let network = TerminalNetworkingComponent()
        .mocked { request in
          if request.path == "/v1/protected-resource" {
            if request.headerFields[.authorization] == "Bearer \(credentials.accessToken)" {
              return .ok()
            } else if request.headerFields[.authorization] == "Bearer \(expired.accessToken)" {
              return .status(.unauthorized)
            }
          } else if request.path == "/api/token" && checkForRefresh(in: request) {
            return try .ok(body: JSONBody(credentials))
          }
          return nil
        }
        .reported(by: reporter)
        .server(prefixPath: "v1")
        .server(authenticationMethod: .stub)
        .authenticated(oauth: stub)

      // Provide expired credentials
      try await network.stubOAuthSystem {
        await $0.set(credentials: expired)
      }

      // Make a request to protected resource
      var request = HTTPRequestData(path: "/protected-resource")
      request.authenticationMethod = .stub
      try await network.data(request)

      let sentRequests = await reporter.requests

      XCTAssertEqual(
        sentRequests.map(\.path),
        [
          "/v1/protected-resource",  // not authorised
          "/api/token",  // refresh token
          "/v1/protected-resource",  // authorized
        ])
    }
  }
}
