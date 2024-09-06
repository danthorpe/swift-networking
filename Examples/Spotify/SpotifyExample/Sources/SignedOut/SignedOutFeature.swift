import ComposableArchitecture
import Foundation
import OAuth
import SpotifyClient

@Reducer
package struct SignedOutFeature {

  @ObservableState
  package enum State {
    case pending
    case active
    case failed(Error)
    case success
  }

  package enum Action: ViewAction {
    case signInResponse(TaskResult<Void>)
    case view(View)
    package enum View {
      case signInButtonTapped
    }
  }

  package init() {}

  @Dependency(\.spotify) var spotify

  package var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .signInResponse(.success):
        state = .success
        return .none
      case let .signInResponse(.failure(error)):
        state = .failed(error)
        return .none
      case .view(.signInButtonTapped):
        return .run { _ in
          try await spotify.signIn(nil)
        }
      }
    }
  }
}
