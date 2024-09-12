import ComposableArchitecture
import ComposableLoadable
import SwiftUI

struct ArtistsView {
  let store: StoreOf<ArtistsFeature>

  #if os(macOS)
  let columns = Array(repeating: GridItem(.fixed(160), spacing: 0), count: 4)
  #elseif os(tvOS)
  let columns = Array(repeating: GridItem(.fixed(256), spacing: 0), count: 5)
  #else
  let columns = Array(repeating: GridItem(.fixed(120), spacing: 0), count: 3)
  #endif
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
      ScrollView(.vertical) {
        LazyVGrid(columns: columns, spacing: 0) {
          ForEach(store.elements.sorted().reversed()) { artist in
            ArtistView(artist: artist)
          }

          PaginationLoadMore(store, direction: .bottom) { error, _ in
            Text("Error fetching next page: \(error)")
          } noMoreResults: {
            Text("No more artists")
          } onActive: {
            ProgressView()
          }
        }
      }
    }
  }
}

struct ArtistView: View {
  @Environment(\.displayScale) var displayScale
  let artist: Artist
  var body: some View {
    ZStack(alignment: .bottom) {
      AsyncImage(url: artist.images.first?.url, scale: displayScale) { phase in
        switch phase {
        case let .success(image):
          image.resizable()
            .aspectRatio(1.0, contentMode: .fit)
        default:
          EmptyView()
        }
      }
      .clipped()

      Text(artist.name)
        .padding(.vertical, 8)
        .frame(maxWidth: .greatestFiniteMagnitude)
        .background(.ultraThinMaterial, in: Rectangle())
    }
  }
}
