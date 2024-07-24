import AuthenticationServices
import ConcurrencyExtras
import Foundation
import Helpers

// MARK: - Public API

public protocol OAuthSystem<Credentials>: Sendable {
  associatedtype Credentials: BearerAuthenticatingCredentials, Sendable

  var callback: String { get }

  func buildAuthorizationURL(
    state: String,
    codeChallenge: String
  ) throws -> URL

  func validate(
    callback: URL,
    state expectedState: String
  ) throws -> String

  func requestCredentials(
    code: String,
    codeVerifier: String,
    using upstream: any NetworkingComponent
  ) async throws -> Credentials
}

// MARK: - Default Implementations

extension OAuthSystem {

  package var callbackScheme: String {
    guard let components = URLComponents(string: callback), let scheme = components.scheme else {
      return callback
    }
    return scheme
  }

  public func extractValueFrom(_ callback: URL, forQueryNamed queryName: String) throws -> String {
    guard
      let value = callback.extractValueForQueryParameterNamed(queryName)
    else {
      throw ErrorMessage(
        message: "Missing query parameter \(queryName): \(callback)"
      )
    }
    return value
  }
}

extension URL {
  fileprivate func extractValueForQueryParameterNamed(_ queryName: String) -> String? {
    guard
      let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
      let queryItems = components.queryItems,
      let value = queryItems.first(where: { $0.name == queryName })?.value
    else { return nil }
    return value
  }
}
