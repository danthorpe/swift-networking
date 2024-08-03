import Foundation

package actor AnyAuthenticationDelegate<Credentials: AuthenticatingCredentials>: AuthenticationDelegate {
  package let delegate: any AuthenticationDelegate<Credentials>

  package init(delegate: some AuthenticationDelegate<Credentials>) {
    self.delegate = delegate
  }

  package func authorize() async throws -> Credentials {
    try await delegate.authorize()
  }

  package func refresh(unauthorized: Credentials, from response: HTTPResponseData) async throws -> Credentials {
    try await delegate.refresh(unauthorized: unauthorized, from: response)
  }
}
