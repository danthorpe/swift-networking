import ComposableArchitecture
import SwiftUI

@ViewAction(for: SignedOutFeature.self)
package struct SignedOutView: View {
  package let store: StoreOf<SignedOutFeature>

  package init(store: StoreOf<SignedOutFeature>) {
    self.store = store
  }

  package var body: some View {
    Button("Sign into Spotify") {
      send(.signInButtonTapped)
    }
  }
}
