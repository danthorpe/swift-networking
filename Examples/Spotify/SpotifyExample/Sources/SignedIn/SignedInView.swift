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
    ) { profileStore in
      Text("Hello, \(profileStore.me.displayName)")
    } onError: { error, _ in
      Text("Error fetching profile: \(error)")
    } onActive: { _ in
      ProgressView()
    }
  }
}
