import AuthenticationServices
import ConcurrencyExtras
import Foundation
import Helpers

// MARK: - Public API

public protocol OAuthSystem<Credentials>: Sendable {
  associatedtype Credentials

  var callbackScheme: String { get }

  var clientSecret: OAuth.ClientSecret { get }

  var credentials: Credentials? { get }

  func authorizationURL() throws -> URL

  func validate(callback: URL) throws -> String

  func requestTokenExchange(
    code: String,
    using upstream: any NetworkingComponent
  ) async throws

  func getBearerCredentials() throws -> BearerCredentials
}

// MARK: - Default Implementations

extension OAuthSystem {

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

  public func validate(callback: URL) throws -> String {
    try extractValueFrom(callback, forQueryNamed: "code")
  }
}

// MARK: - Implementation Details

// MARK: - Requests etc

// MARK: - Temporary

extension URL {
  public func extractValueForQueryParameterNamed(_ queryName: String) -> String? {
    guard
      let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
      let queryItems = components.queryItems,
      let value = queryItems.first(where: { $0.name == queryName })?.value
    else { return nil }
    return value
  }
}
