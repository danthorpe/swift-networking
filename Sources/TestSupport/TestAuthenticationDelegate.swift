import Networking
import Protected
import XCTestDynamicOverlay

public final class TestAuthenticationDelegate<Credentials: AuthenticatingCredentials>: @unchecked
  Sendable
{
  public typealias Fetch = @Sendable (HTTPRequestData) async throws -> Credentials
  public typealias Refresh = @Sendable (Credentials, HTTPResponseData) async throws -> Credentials

  @Protected public var fetchCount: Int = 0
  @Protected public var refreshCount: Int = 0

  public var fetch: Fetch
  public var refresh: Refresh

  public init(
    fetch: @escaping Fetch = unimplemented("TestAuthenticationDelegate.fetch"),
    refresh: @escaping Refresh = unimplemented("TestAuthenticationDelegate.refresh")
  ) {
    self.fetch = fetch
    self.refresh = refresh
  }
}

extension TestAuthenticationDelegate: AuthenticationDelegate {
  public func fetch(for request: HTTPRequestData) async throws -> Credentials {
    fetchCount += 1
    return try await fetch(request)
  }

  public func refresh(
    unauthorized credentials: Credentials,
    from response: HTTPResponseData
  ) async throws -> Credentials {
    refreshCount += 1
    return try await refresh(credentials, response)
  }
}
