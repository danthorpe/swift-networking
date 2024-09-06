import Networking

extension Spotify {
  package struct User: Sendable, Equatable, Codable {
    package let displayName: String
    package let email: String
    package let id: String
    package let type: String
    package let uri: String
  }
}

extension Request where Body == Spotify.User {
  static var me: Self {
    Request(http: HTTPRequestData(path: "me"), decoder: Spotify.decoder)
  }
}
