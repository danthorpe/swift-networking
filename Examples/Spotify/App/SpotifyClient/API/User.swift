import Networking

struct User: Sendable, Equatable, Codable, Identifiable {
  let displayName: String
  let email: String
  let id: String
  let type: String
  let uri: String
}

extension Request where Response == User {
  static var me: Self {
    Request(http: HTTPRequestData(path: "me"), decoder: Spotify.decoder)
  }
}
