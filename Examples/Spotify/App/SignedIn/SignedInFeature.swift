import ComposableArchitecture
import ComposableLoadable
import Tagged

@Reducer
struct SignedInFeature {

  @ObservableState
  struct State {
    @ObservationStateIgnored
    @LoadableStateWith<EmptyLoadRequest, ArtistsFeature> var followedArtists

    init(
      followedArtists: LoadableStateWith<EmptyLoadRequest, ArtistsFeature>
    ) {
      self._followedArtists = followedArtists
    }

    init() {
      self.init(followedArtists: .pending)
    }
  }

  enum Action {
    case followedArtists(LoadingActionWith<EmptyLoadRequest, ArtistsFeature>)
  }

  @Dependency(\.spotify) var spotify

  init() {}

  var body: some ReducerOf<Self> {
    Reduce { _, action in
      switch action {
      case .followedArtists:
        return .none
      }
    }
    .loadable(\.$followedArtists, action: \.followedArtists) {
      Reduce(ArtistsFeature.body)
    } load: { _ in
      let artists = try await spotify.followedArtists().artists
      guard artists.items.isEmpty else {
        return .artists(
          PaginationFeature<Artist>
            .State(
              selection: artists.items.first!.id,
              next: artists.cursors.after,
              elements: artists.items
            )
        )
      }
      return .empty
    }
  }
}
