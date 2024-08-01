import Foundation

package actor StreamingAuthenticationDelegate<Delegate: AuthenticationDelegate>: AuthenticationDelegate {
  package let delegate: Delegate
  private let (stream, continuation) = AsyncStream<Delegate.Credentials>.makeStream()

  package var credentials: AsyncStream<Delegate.Credentials> {
    stream.shared().eraseToStream()
  }

  package init(delegate: Delegate) {
    self.delegate = delegate
  }

  package func authorize() async throws -> Delegate.Credentials {
    let credentials = try await delegate.authorize()
    continuation.yield(credentials)
    return credentials
  }

  package func refresh(unauthorized: Delegate.Credentials, from response: HTTPResponseData) async throws
    -> Delegate.Credentials
  {
    let credentials = try await delegate.refresh(unauthorized: unauthorized, from: response)
    continuation.yield(credentials)
    return credentials
  }
}
