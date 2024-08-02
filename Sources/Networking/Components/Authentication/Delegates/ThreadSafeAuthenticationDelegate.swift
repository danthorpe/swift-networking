import Foundation

/// A thread safe wrapper of AuthenticationDelegate
///
/// This type can assist by providing thread-safety, requiring only
/// that a basic struct implementing authorization logic be required.
package actor ThreadSafeAuthenticationDelegate<Delegate: AuthenticationDelegate>: AuthenticationDelegate {
  package enum State {
    case idle
    case fetching(Task<Delegate.Credentials, Error>)
    case authorized(Delegate.Credentials)
  }

  package let delegate: Delegate
  package private(set) var state: State = .idle

  @NetworkEnvironment(\.logger) var logger

  package init(delegate: Delegate) {
    self.delegate = delegate
  }

  private func set(state: State) {
    self.state = state
  }

  package func set(credentials: Delegate.Credentials) async {
    switch state {
    case .idle, .authorized:
      set(state: .authorized(credentials))
    case let .fetching(task):
      task.cancel()
      set(state: .authorized(credentials))
    }
  }

  package func removeCredentials() async {
    set(state: .idle)
  }

  package func authorize() async throws -> Delegate.Credentials {
    switch state {
    case let .authorized(credentials):
      return credentials
    case let .fetching(task):
      return try await task.value
    case .idle:
      let task = Task { try await performAuthorize() }
      set(state: .fetching(task))
      return try await task.value
    }
  }

  package func refresh(
    unauthorized credentials: Delegate.Credentials,
    from response: HTTPResponseData
  ) async throws -> Delegate.Credentials {
    if case let .fetching(task) = state {
      return try await task.value
    }

    let task = Task {
      try await performCredentialRefresh(unauthorized: credentials, from: response)
    }
    set(state: .fetching(task))
    return try await task.value
  }

  private func performAuthorize() async throws -> Delegate.Credentials {
    logger?
      .info(
        "🔐 Fetching credentials for \(Delegate.Credentials.method.rawValue, privacy: .public) authorization method"
      )
    do {
      let credentials = try await delegate.authorize()
      set(state: .authorized(credentials))
      return credentials
    } catch {
      set(state: .idle)
      throw error
    }
  }

  private func performCredentialRefresh(
    unauthorized credentials: Delegate.Credentials,
    from response: HTTPResponseData
  ) async throws -> Delegate.Credentials {
    logger?
      .info(
        "🔑 Refreshing credentials for \(Delegate.Credentials.method.rawValue, privacy: .public) authorization method"
      )
    do {
      let refreshed = try await delegate.refresh(unauthorized: credentials, from: response)
      set(state: .authorized(refreshed))
      return refreshed
    } catch {
      set(state: .idle)
      throw AuthenticationError.refreshCredentialsFailed(response, Delegate.Credentials.method, error)
    }
  }
}

extension ThreadSafeAuthenticationDelegate.State: Equatable where Delegate.Credentials: Equatable {}
