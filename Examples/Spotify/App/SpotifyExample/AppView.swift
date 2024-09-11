import ComposableArchitecture
import SwiftUI

public struct AppFeatureView {
  let store: StoreOf<AppFeature>
  init(store: StoreOf<AppFeature>) {
    self.store = store
  }
  public init() {
    self.init(
      store: Store(
        initialState: .pending
      ) { AppFeature() }
    )
  }
}

extension AppFeatureView: View {
  public var body: some View {
    contentView
      .task { await store.send(.view(.onTask)).finish() }
  }

  @ViewBuilder
  private var contentView: some View {
    switch store.state {
    case .pending:
      ProgressView()
    case .signedIn:
      if let store = store.scope(state: \.signedIn, action: \.signedIn) {
        SignedInView(store: store)
      }
    case .signedOut:
      if let store = store.scope(state: \.signedOut, action: \.signedOut) {
        SignedOutView(store: store)
      }
    }
  }
}
