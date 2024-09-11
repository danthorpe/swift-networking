import ComposableArchitecture
import ComposableLoadable
import SwiftUI

@ViewAction(for: SignedInFeature.self)
struct SignedInView: View {
  let store: StoreOf<SignedInFeature>

  init(store: StoreOf<SignedInFeature>) {
    self.store = store
  }

  var body: some View {
    NavigationView {
      contentView
    }
  }

  var contentView: some View {
    LoadableView(
      loadOnAppear: store.scope(state: \.$followedArtists, action: \.followedArtists)
    ) { artistsStore in
      ArtistsView(store: artistsStore)
        .navigationTitle("Followed Artists")
        .toolbar {
          ToolbarItemGroup(placement: .bottomBar) {
            Button("Logout") {
              send(.logoutButtonTapped)
            }
          }
        }
    } onError: { error, _ in
      Text("Error fetching artists: \(error)")
    } onActive: { _ in
      ProgressView()
    }
  }
}
