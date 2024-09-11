import ComposableArchitecture
import ComposableLoadable
import SwiftUI

struct ArtistsView {
  let store: StoreOf<ArtistsFeature>
}

extension ArtistsView: View {

  var body: some View {
    WithPerceptionTracking {
      contentView
    }
  }

  @ViewBuilder
  private var contentView: some View {
    switch store.case {
    case .empty:
      Text("No Artists")
    case let .artists(store):
      ForEach(store.elements) { artist in
        Text(artist.name)
      }
    }
  }
}
