import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct AppFeatureView {
  let store: StoreOf<AppFeature>
  init(store: StoreOf<AppFeature>) {
    self.store = store
  }
  init() {
    self.init(
      store: Store(
        initialState: .pending
      ) { AppFeature() }
    )
  }
}

extension AppFeatureView: View {
  var body: some View {
    contentView
      .task { await send(.onTask).finish() }
  }

  @ViewBuilder
  private var contentView: some View {
    switch store.state {
    case .pending:
      ProgressView()
    case .signedIn:
      if let signedInStore = store.scope(state: \.signedIn, action: \.signedIn) {
        SignedInView(store: signedInStore)
          .toolbar {
            ToolbarItemGroup(placement: .automatic) {
              Button("Sign Out") {
                send(.signOutButtonTapped)
              }
            }
          }
      }
    case .signedOut:
      if let store = store.scope(state: \.signedOut, action: \.signedOut) {
        SignedOutView(store: store)
      }
    }
  }
}
