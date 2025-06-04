import AsyncAlgorithms
import ComposableArchitecture
import Foundation
import Networking
import OAuth

@testable import SpotifyApp

extension Spotify.Credentials {
  static let mock = Self.mock()
  static func mock(
    accessToken: String = "access",
    expiresIn: Int = 100,
    refreshToken: String = "refresh",
    scope: String? = "scopes",
    tokenType: String = "spotify"
  ) -> Spotify.Credentials {
    Spotify.Credentials(
      accessToken: accessToken,
      expiresIn: expiresIn,
      refreshToken: refreshToken,
      scope: scope,
      tokenType: tokenType
    )
  }
}

extension Artist {
  static let taylorSwift = Artist(
    id: "06HL4z0CvFAxyc27GXpf02",
    name: "Taylor Swift",
    genres: ["pop"],
    href: "https://api.spotify.com/v1/artists/06HL4z0CvFAxyc27GXpf02",
    images: [
      Image(url: "https://i.scdn.co/image/ab6761610000e5ebe672b5f553298dcdccb0e676", height: 640, width: 640),
      Image(url: "https://i.scdn.co/image/ab67616100005174e672b5f553298dcdccb0e676", height: 320, width: 320),
      Image(url: "https://i.scdn.co/image/ab6761610000f178e672b5f553298dcdccb0e676", height: 160, width: 160),
    ],
    popularity: 100,
    type: "artist",
    uri: "spotify:artist:06HL4z0CvFAxyc27GXpf02"
  )
}

// MARK: - Test Helpers

extension URL {
  init(static staticString: StaticString) {
    guard let url = URL(string: String(describing: staticString)) else {
      fatalError("Static string is not a valid URL")
    }
    self = url
  }
}

extension URL: @retroactive ExpressibleByStringLiteral {
  public init(stringLiteral value: StaticString) {
    self.init(static: value)
  }
}
