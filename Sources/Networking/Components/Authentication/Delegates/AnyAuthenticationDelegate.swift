import Foundation

actor AnyAuthenticationDelegate<Credentials: AuthenticatingCredentials>: AuthenticationDelegate {
  let delegate: any AuthenticationDelegate<Credentials>

  init(delegate: some AuthenticationDelegate<Credentials>) {
    self.delegate = delegate
  }

  func authorize() async throws -> Credentials {
    try await delegate.authorize()
  }

  func refresh(unauthorized: Credentials, from response: HTTPResponseData) async throws -> Credentials {
    try await delegate.refresh(unauthorized: unauthorized, from: response)
  }
}
