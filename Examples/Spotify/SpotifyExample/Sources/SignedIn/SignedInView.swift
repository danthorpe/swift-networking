import ComposableArchitecture
import ComposableLoadable
import SwiftUI

package struct SignedInView: View {
  let store: StoreOf<SignedInFeature>

  package init(store: StoreOf<SignedInFeature>) {
    self.store = store
  }

  package var body: some View {
    LoadableView(
      loadOnAppear: store.scope(state: \.$me, action: \.me)
    ) { _ in
      //      Text("Hello, \(profileStore.me.displayName)")
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
      Text("First artist: \(artistsStore.artists.elements.first?.name ?? "no artists")")
    } onError: { error, _ in
      Text("Error fetching artists: \(error)")
    } onActive: { _ in
      ProgressView()
    }
  }
}
