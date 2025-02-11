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
struct OAuthDelegateTests: TestableNetwork {
  let reporter = TestReporter()
  let stub = StubOAuthSystem(
    authorizationEndpoint: "https://accounts.example.com/authorize",
    tokenEndpoint: "https://accounts.example.com/api/token",
    clientId: "some-client-id",
    redirectURI: "some-redirect-uri://callback",
    scope: "some-scope"
  )
  let credentials = StubOAuthSystem.Credentials(
    accessToken: "access-token",
    refreshToken: "refresh-token"
  )

  @Test func test__authentication_delegate__fetches_credentials() async throws {
    try await withTestDependencies {
      $0.webAuthenticationSession = WebAuthenticationSessionClient { [redirect = stub.redirectURI] state, _, _, _ in
        URL(string: "\(redirect)?state=\(state)&code=abc123")!
      }
      $0.oauthSystems = .basic()
    } operation: {

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

      // Configure Network
      try await network.stubOAuthSystem {
        await $0.signOut()
        await $0.set(presentationContext: DefaultPresentationContext())
      }

      // Make a request to protected resource
      var request = HTTPRequestData(path: "/protected-resource")
      request.authenticationMethod = .stub
      try await network.data(request)

      let sentRequests = await reporter.requests

      #expect(
        sentRequests.map(\.path) == [
          "/api/token",
          "/v1/protected-resource",
        ])
    }
  }

  @Test func test__given_already_has_credentials__authentication_delegate_does_not_fetch_credentials() async throws {
    try await withTestDependencies {
      $0.webAuthenticationSession = WebAuthenticationSessionClient { [redirect = stub.redirectURI] state, _, _, _ in
        URL(string: "\(redirect)?state=\(state)&code=abc123")!
      }
      $0.oauthSystems = .basic()
    } operation: {

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
        await $0.set(presentationContext: DefaultPresentationContext())
      }

      // Make a request to protected resource
      var request = HTTPRequestData(path: "/protected-resource")
      request.authenticationMethod = .stub
      try await network.data(request)
    }

    let sentRequests = await reporter.requests

    #expect(
      sentRequests.map(\.path) == [
        "/v1/protected-resource"
      ])

  }

  @Test func test__given_already_has_expired_credentials__authentication_delegate_refreshes_credentials() async throws {
    let expired = StubOAuthSystem.Credentials(
      accessToken: "expired-access-token",
      refreshToken: "refresh-token"
    )
    try await withTestDependencies {
      $0.webAuthenticationSession = WebAuthenticationSessionClient { [redirect = stub.redirectURI] state, _, _, _ in
        URL(string: "\(redirect)?state=\(state)&code=abc123")!
      }
      $0.oauthSystems = .basic()
    } operation: {

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

      #expect(
        sentRequests.map(\.path) == [
          "/v1/protected-resource",  // not authorised
          "/api/token",  // refresh token
          "/v1/protected-resource",  // authorized
        ])
    }
  }
}
