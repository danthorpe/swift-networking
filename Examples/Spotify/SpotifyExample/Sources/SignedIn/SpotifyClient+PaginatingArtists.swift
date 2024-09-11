import ComposableLoadable
import SpotifyClient

extension Spotify.Client {
  func paginateFollowedArtists(
    _ request: PaginationFeature<Artist>.PageRequest
  ) async throws -> PaginationFeature<Artist>.Page {
    let artists = try await followedArtists(request.cursor, nil).artists
    return PaginationFeature<Artist>
      .Page(
        previous: artists.cursors.before,
        next: artists.cursors.after,
        elements: artists.items
      )
  }
}
