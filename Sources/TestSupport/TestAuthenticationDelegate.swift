import Networking
import Protected
import XCTestDynamicOverlay

public actor TestAuthenticationDelegate<Credentials: AuthenticatingCredentials>: Sendable {
  public typealias Authorize = @Sendable () async throws -> Credentials
  public typealias Refresh = @Sendable (Credentials, HTTPResponseData) async throws -> Credentials

  public var authorizeCount: Int = 0
  public var refreshCount: Int = 0

  public var performAuthorize: Authorize
  public var performRefresh: Refresh

  public init(
    authorize: @escaping Authorize = unimplemented("TestAuthenticationDelegate.authorize"),
    refresh: @escaping Refresh = unimplemented("TestAuthenticationDelegate.refresh")
  ) {
    self.performAuthorize = authorize
    self.performRefresh = refresh
  }
}

extension TestAuthenticationDelegate: AuthenticationDelegate {

  public func authorize() async throws -> Credentials {
    authorizeCount += 1
    return try await performAuthorize()
  }

  public func refresh(
    unauthorized credentials: Credentials,
    from response: HTTPResponseData
  ) async throws -> Credentials {
    refreshCount += 1
    return try await performRefresh(credentials, response)
  }
}
