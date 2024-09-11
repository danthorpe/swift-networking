import ComposableArchitecture
import ComposableLoadable
import Foundation
import SpotifyClient

@Reducer
package struct ArtistsFeature {
  @ObservableState
  package struct State {
    var artists: PaginationFeature<Artist>.State
  }
  package enum Action {
    case artists(PaginationFeature<Artist>.Action)
  }
  let loadPage: PaginationFeature<Artist>.LoadPage

  init(loadPage: @escaping PaginationFeature<Artist>.LoadPage) {
    self.loadPage = loadPage
  }

  init() {
    @Dependency(\.spotify) var spotify
    self.init { request in
      try await spotify.paginateFollowedArtists(request)
    }
  }

  package var body: some ReducerOf<Self> {
    Scope(state: \.artists, action: \.artists) {
      PaginationFeature<Artist>(loadPage: loadPage)
    }
  }
}

extension String: Error {}
