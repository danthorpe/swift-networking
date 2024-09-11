import ComposableArchitecture
import ComposableLoadable
import Foundation

@Reducer
enum ArtistsFeature {
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
