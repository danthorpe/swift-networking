public struct HeaderBasedAuthentication<Delegate: AuthenticationDelegate> {
  actor StateMachine: AuthenticationDelegate {
    typealias Credentials = Delegate.Credentials

    private enum State {
      case idle
      case fetching(Task<Credentials, Error>)
      case authorized(Credentials)
    }

    let delegate: Delegate
    private var state: State = .idle

    @NetworkEnvironment(\.logger) var logger

    init(delegate: Delegate) {
      self.delegate = delegate
    }

    private func set(state: State) {
      self.state = state
    }

    func fetch(for request: HTTPRequestData) async throws -> Credentials {
      switch state {
      case let .authorized(credentials):
        return credentials
      case let .fetching(task):
        return try await task.value
      case .idle:
        let task = Task { try await performCredentialFetch(for: request) }
        set(state: .fetching(task))
        return try await task.value
      }
    }

    private func performCredentialFetch(for request: HTTPRequestData) async throws -> Credentials {
      logger?.info(
        "🔐 Fetching credentials for \(Credentials.method.rawValue, privacy: .public) authorization method"
      )
      do {
        let credentials = try await delegate.fetch(for: request)
        set(state: .authorized(credentials))
        return credentials
      } catch {
        set(state: .idle)
        throw AuthenticationError.fetchCredentialsFailed(request, Credentials.method, error)
      }
    }

    func refresh(unauthorized credentials: Credentials, from response: HTTPResponseData)
      async throws -> Credentials {
      if case let .fetching(task) = state {
        return try await task.value
      }

      let task = Task {
        try await performCredentialRefresh(unauthorized: credentials, from: response)
      }
      set(state: .fetching(task))
      return try await task.value
    }

    private func performCredentialRefresh(
      unauthorized credentials: Credentials,
      from response: HTTPResponseData
    ) async throws -> Credentials {
      logger?.info(
        "🔑 Refreshing credentials for \(Credentials.method.rawValue, privacy: .public) authorization method"
      )
      do {
        let refreshed = try await delegate.refresh(unauthorized: credentials, from: response)
        set(state: .authorized(refreshed))
        return refreshed
      } catch {
        set(state: .idle)
        throw AuthenticationError.refreshCredentialsFailed(response, Credentials.method, error)
      }
    }
  }

  fileprivate let state: StateMachine

  public init(delegate: Delegate) {
    state = StateMachine(delegate: delegate)
  }
}

extension HeaderBasedAuthentication: AuthenticationDelegate {
  public typealias Credentials = Delegate.Credentials
  public func fetch(for request: HTTPRequestData) async throws -> Credentials {
    try await state.fetch(for: request)
  }
  public func refresh(
    unauthorized credentials: Credentials, from response: HTTPResponseData
  ) async throws -> Credentials {
    try await state.refresh(unauthorized: credentials, from: response)
  }
}
