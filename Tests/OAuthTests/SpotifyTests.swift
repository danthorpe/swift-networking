import Foundation
import Networking
import TestSupport
import XCTest

@testable import OAuth

final class SpotifyTests: NetworkingTestCase {

  func test__spotify_endpoints() {
    let spotify: any StandardOAuthSystem = .spotify(
      clientId: "some-client-id",
      callback: "some-redirect-callback://spotify",
      scope: "spotify-scope"
    )
    XCTAssertEqual(spotify.authorizationEndpoint, "https://accounts.spotify.com/authorize")
    XCTAssertEqual(spotify.tokenEndpoint, "https://accounts.spotify.com/api/token")
  }

  func test__create_spotify_convenience() async throws {
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
