import Foundation

actor StreamingAuthenticationDelegate<Delegate: AuthenticationDelegate>: AuthenticationDelegate {
  let delegate: Delegate
  private let (stream, continuation) = AsyncStream<Delegate.Credentials>.makeStream()

  var credentials: AsyncStream<Delegate.Credentials> {
    stream.shared().eraseToStream()
  }

  init(delegate: Delegate) {
    self.delegate = delegate
  }

  func authorize() async throws -> Delegate.Credentials {
    let credentials = try await delegate.authorize()
    continuation.yield(credentials)
    return credentials
  }

  func refresh(unauthorized: Delegate.Credentials, from response: HTTPResponseData) async throws -> Delegate.Credentials
  {
    let credentials = try await delegate.refresh(unauthorized: unauthorized, from: response)
    continuation.yield(credentials)
    return credentials
  }
}
