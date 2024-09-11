import ComposableArchitecture
import SwiftUI

@ViewAction(for: SignedOutFeature.self)
struct SignedOutView: View {
  let store: StoreOf<SignedOutFeature>

  init(store: StoreOf<SignedOutFeature>) {
    self.store = store
  }

  var body: some View {
    Button("Sign into Spotify") {
      send(.signInButtonTapped)
    }
  }
}
