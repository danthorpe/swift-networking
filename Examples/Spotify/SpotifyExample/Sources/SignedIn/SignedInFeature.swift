import ComposableArchitecture
import ComposableLoadable
import SpotifyClient

@Reducer
package struct SignedInFeature {

  @ObservableState
  package struct State {
    @ObservationStateIgnored
    @LoadableStateOf<ProfileFeature> var me

    package init(
      me: LoadableStateOf<ProfileFeature> = .pending
    ) {
      self._me = me
    }
  }

  package enum Action {
    case me(LoadingActionOf<ProfileFeature>)
  }

  @Dependency(\.spotify) var spotify

  package init() {}

  package var body: some ReducerOf<Self> {
    Reduce { _, action in
      switch action {
      case .me:
        return .none
      }
    }
    .loadable(\.$me, action: \.me) {
      ProfileFeature()
    } load: { _ in
      ProfileFeature.State(
        me: try await spotify.me()
      )
    }
  }
}
