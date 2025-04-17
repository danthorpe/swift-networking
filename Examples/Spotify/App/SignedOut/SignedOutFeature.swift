import ComposableArchitecture
import Foundation
import OAuth

@Reducer
struct SignedOutFeature {

  @ObservableState
  enum State: Equatable {
    case pending
    case active
    case failed
    case success
  }

  enum Action: ViewAction {
    case signInResponse(TaskResult<Bool>)
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
        // TODO: Create a specific equatable Error Type
        print("Error performing sign in: \(String(describing: error))")
        state = .failed
        return .none
      case .view(.signInButtonTapped):
        return .run { send in
          try await spotify.signIn(presentationContext: DefaultPresentationContext())
          await send(.signInResponse(.success(true)))
        } catch: { error, send in
          await send(.signInResponse(.failure(error)))
        }
      }
    }
  }
}
