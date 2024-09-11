import ComposableArchitecture
import ComposableLoadable
import SwiftUI

struct SignedInView: View {
  let store: StoreOf<SignedInFeature>

  init(store: StoreOf<SignedInFeature>) {
    self.store = store
  }

  var body: some View {
    LoadableView(
      loadOnAppear: store.scope(state: \.$me, action: \.me)
    ) { _ in
      loadArtists
    } onError: { error, _ in
      Text("Error fetching profile: \(error)")
    } onActive: { _ in
      ProgressView()
    }
  }

  private var loadArtists: some View {
    LoadableView(
      loadOnAppear: store.scope(state: \.$followedArtists, action: \.followedArtists)
    ) { artistsStore in
      ArtistsView(store: artistsStore)
    } onError: { error, _ in
      Text("Error fetching artists: \(error)")
    } onActive: { _ in
      ProgressView()
    }
  }
}
