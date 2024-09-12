import ComposableArchitecture
import Foundation
import OAuth

@Reducer
struct SignedOutFeature {

  @ObservableState
  enum State {
    case pending
    case active
    case failed(Error)
    case success
  }

  enum Action: ViewAction {
    case signInResponse(TaskResult<Void>)
    case view(View)
    enum View {
      case signInButtonTapped
    }
  }

  init() {}

  @Dependency(\.spotify) var spotify

  var body: some ReducerOf<Self> {
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
