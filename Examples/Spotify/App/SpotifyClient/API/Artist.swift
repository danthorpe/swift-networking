import Foundation
import Networking
import Tagged

struct Artist: Sendable, Equatable, Codable, Identifiable {
  let id: Tagged<Self, String>
  let name: String
  let genres: [String]
  let href: String
  let images: [Image]
  let popularity: Int
  let type: String
  let uri: String
}

struct Image: Sendable, Equatable, Codable {
  let url: URL
  let height: Int
  let width: Int
}

extension Artist: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.popularity < rhs.popularity
  }
}

struct Artists: Sendable, Equatable, Codable {
  let artists: PagedList<Artist>
}

extension Request where Body == Artists {
  static func followedArtists(after: String? = nil, limit: Int? = nil) -> Self {
    var http = HTTPRequestData(path: "me/following")
    http.type = "artist"
    if let limit {
      http.limit = "\(limit)"
    }
    if let after {
      http.after = after
    }
    return Request(http: http, decoder: Spotify.decoder)
  }
}

struct PagedList<Item: Sendable & Equatable & Codable>: Sendable, Equatable, Codable {
  struct Cursors: Sendable, Equatable, Codable {
    let before: String?
    let after: String?
  }
  let href: String
  let limit: Int
  let total: Int
  let cursors: Cursors
  let items: [Item]
}
