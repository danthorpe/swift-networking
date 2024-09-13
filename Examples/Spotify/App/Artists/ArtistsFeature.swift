import ComposableArchitecture
import ComposableLoadable
import Foundation

@Reducer(state: .equatable, action: .equatable)
enum ArtistsFeature: Equatable {
  @ReducerCaseIgnored
  case empty
  case artists(PaginationFeature<Artist>)
}

extension PaginationFeature<Artist> {
  init() {
    @Dependency(\.spotify) var spotify
    self.init(loadPage: spotify.paginateFollowedArtists)
  }
}
