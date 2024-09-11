import Networking

package struct User: Sendable, Equatable, Codable, Identifiable {
  package let displayName: String
  package let email: String
  package let id: String
  package let type: String
  package let uri: String
}

extension Request where Body == User {
  static var me: Self {
    Request(http: HTTPRequestData(path: "me"), decoder: Spotify.decoder)
  }
}
