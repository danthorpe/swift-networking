import Foundation
import Networking
import OAuth

extension AuthenticationMethod {
  static let stub = AuthenticationMethod(rawValue: "stub")
}

struct StubOAuthSystem: StandardOAuthSystem {
  struct Credentials: OAuthCredentials, Equatable {
    static let method: AuthenticationMethod = .stub
    let accessToken: String
    let refreshToken: String
  }
  let authorizationEndpoint: String
  let tokenEndpoint: String
  let clientId: String
  let redirectURI: String
  let scope: String?
}

extension NetworkingComponent {
  func stubOAuthSystem<ReturnValue: Sendable>(
    perform: @MainActor (any OAuthProxy<StubOAuthSystem.Credentials>) async throws -> ReturnValue
  ) async throws -> ReturnValue {
    try await oauth(of: StubOAuthSystem.Credentials.self, perform: perform)
  }
}
