import AsyncAlgorithms
import ComposableArchitecture
import ComposableLoadable
import Networking
import OAuth
import XCTest

@testable import SpotifyApp

final class SignedInFeatureTests: XCTestCase {

  @MainActor func test__given_load__when_no_artists__then_artist_state_is_empty() async throws {
    let store = TestStore(initialState: SignedInFeature.State()) {
      SignedInFeature()
    } withDependencies: {
      $0.spotify.followedArtists = { @Sendable _, limit in
        XCTAssertEqual(limit, 10)
        return Artists(
          artists: PagedList<Artist>(
            href: "https://this.is.a.link.to.spotify.com",
            limit: 0,
            total: 0,
            cursors: PagedList<Artist>
              .Cursors(
                before: nil,
                after: nil
              ),
            items: []
          )
        )
      }
    }
    await store.send(.followedArtists(.load)) {
      $0.$followedArtists = .active
    }
    await store.receive({ $0.is(\.followedArtists) }, timeout: .zero) {
      $0.$followedArtists.finish(.success(.empty))
    }
  }

  @MainActor func test__given_load__then_spotify_returns_artists() async throws {
    let expectedArtists = [Artist.taylorSwift]

    let store = TestStore(initialState: SignedInFeature.State()) {
      SignedInFeature()
    } withDependencies: {
      $0.spotify.followedArtists = { @Sendable _, limit in
        XCTAssertEqual(limit, 10)
        return Artists(
          artists: PagedList<Artist>(
            href: "https://this.is.a.link.to.spotify.com",
            limit: 1,
            total: 1,
            cursors: PagedList<Artist>
              .Cursors(
                before: nil,
                after: nil
              ),
            items: expectedArtists
          )
        )
      }
    }
    await store.send(.followedArtists(.load)) {
      $0.$followedArtists = .active
    }
    let expectedArtistFeatureState: ArtistsFeature.State = .artists(
      PaginationFeature<Artist>
        .State(
          selection: Artist.taylorSwift.id,
          next: nil,
          elements: expectedArtists
        )
    )
    await store.receive({ $0.is(\.followedArtists) }, timeout: .zero) {
      $0.$followedArtists.finish(.success(expectedArtistFeatureState))
    }
  }
}
