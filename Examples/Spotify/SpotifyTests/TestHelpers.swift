import AsyncAlgorithms
import ComposableArchitecture
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

// MARK: - Test Helpers

extension TestDependencyKey {
  /// Override any property of a TestDependency.
  func override<Property>(_ keyPath: WritableKeyPath<Self, Property>, with property: Property) -> Self {
    var copy = self
    copy[keyPath: keyPath] = property
    return copy
  }
}
