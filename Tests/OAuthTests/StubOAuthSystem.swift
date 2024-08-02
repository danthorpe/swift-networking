import Foundation
import Networking
import OAuth

extension AuthenticationMethod {
  static let stub = AuthenticationMethod(rawValue: "stub")
}

struct StubOAuthSystem: StandardOAuthSystem {
  struct Credentials: OAuthCredentials, Equatable {
    let accessToken: String
    let refreshToken: String
  }
  let authorizationEndpoint: String
  let tokenEndpoint: String
  let clientId: String
  let redirectURI: String
  let scope: String?
}
