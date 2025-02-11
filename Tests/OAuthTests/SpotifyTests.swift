import Foundation
import Networking
import TestSupport
import Testing

@testable import OAuth

@Suite
struct SpotifyTests: TestableNetwork {

  @Test func test__spotify_endpoints() {
    let spotify: any StandardOAuthSystem = .spotify(
      clientId: "some-client-id",
      callback: "some-redirect-callback://spotify",
      scope: "spotify-scope"
    )
    #expect(spotify.authorizationEndpoint == "https://accounts.spotify.com/authorize")
    #expect(spotify.tokenEndpoint == "https://accounts.spotify.com/api/token")
  }

  @Test func test__create_spotify_convenience() async throws {
    try await withTestDependencies {
      $0.oauthSystems = .basic()
    } operation: {
      let network = TerminalNetworkingComponent()
        .authenticated(
          oauth: .spotify(
            clientId: "some-client-id",
            callback: "some-redirect-callback://spotify",
            scope: "spotify-scope"
          )
        )

      try await network.spotify { _ in
        // no-op
      }
    }
  }
}
