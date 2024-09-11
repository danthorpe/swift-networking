import Foundation
import Networking
import Tagged

package struct Artist: Sendable, Equatable, Codable, Identifiable {
  package let id: Tagged<Self, String>
  package let name: String
  package let genres: [String]
  package let href: String
  package let images: [Image]
  package let popularity: Int
  package let type: String
  package let uri: String
}

package struct Image: Sendable, Equatable, Codable {
  package let url: URL
  package let height: Int
  package let width: Int
}

package struct Artists: Sendable, Equatable, Codable {
  package let artists: PagedList<Artist>
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

package struct PagedList<Item: Sendable & Equatable & Codable>: Sendable, Equatable, Codable {
  package struct Cursors: Sendable, Equatable, Codable {
    package let before: String?
    package let after: String?
  }
  package let href: String
  package let limit: Int
  package let total: Int
  package let cursors: Cursors
  package let items: [Item]
}
