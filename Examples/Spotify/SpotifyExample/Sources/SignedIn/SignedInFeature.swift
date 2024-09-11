import ComposableArchitecture
import ComposableLoadable
import SpotifyClient
import Tagged

@Reducer
package struct SignedInFeature {

  @ObservableState
  package struct State {
    @ObservationStateIgnored
    @LoadableStateOf<ProfileFeature> var me

    @ObservationStateIgnored
    @LoadableStateWith<EmptyLoadRequest, ArtistsFeature> var followedArtists

    init(
      me: LoadableStateOf<ProfileFeature>,
      followedArtists: LoadableStateWith<EmptyLoadRequest, ArtistsFeature>
    ) {
      self._me = me
      self._followedArtists = followedArtists
    }

    package init() {
      self.init(me: .pending, followedArtists: .pending)
    }
  }

  package enum Action {
    case me(LoadingActionOf<ProfileFeature>)
    case followedArtists(LoadingActionWith<EmptyLoadRequest, ArtistsFeature>)
  }

  @Dependency(\.spotify) var spotify

  package init() {}

  package var body: some ReducerOf<Self> {
    Reduce { _, action in
      switch action {
      case .me:
        return .none
      case .followedArtists:
        return .none
      }
    }
    .loadable(\.$me, action: \.me) {
      ProfileFeature()
    } load: { _ in
      let user = try await spotify.me()
      return ProfileFeature.State(
        me: user
      )
    }
    .loadable(\.$followedArtists, action: \.followedArtists) {
      ArtistsFeature()
    } load: { _ in
      let artists = try await spotify.followedArtists(nil, nil).artists
      return ArtistsFeature.State(
        artists: PaginationFeature<Artist>
          .State(
            selection: artists.items.first!.id,
            next: artists.cursors.after,
            elements: artists.items
          )
      )
    }
  }
}
