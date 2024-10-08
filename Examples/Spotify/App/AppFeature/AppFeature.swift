import ComposableArchitecture
import Foundation
import OAuth

@Reducer
struct AppFeature {

  @ObservableState
  enum State: Equatable {
    case pending
    case signedOut(SignedOutFeature.State)
    case signedIn(SignedInFeature.State)
  }

  enum Action: ViewAction {
    case credentialsDidChange(OAuth.AvailableSystems.Spotify.Credentials)
    case signedInSuccess
    case signedOutSuccess
    case signedIn(SignedInFeature.Action)
    case signedOut(SignedOutFeature.Action)
    case view(View)

    enum View {
      case onTask
      case signOutButtonTapped
    }
  }

  // TODO: Store existing Spotify credentials in the Keychain
  @Shared(.fileStorage(.credentials)) var credentials: OAuth.AvailableSystems.Spotify.Credentials?

  @Dependency(\.spotify) var spotify

  var body: some ReducerOf<Self> {
    Scope(state: \.signedIn, action: \.signedIn) {
      SignedInFeature()
    }
    Scope(state: \.signedOut, action: \.signedOut) {
      SignedOutFeature()
    }
    Reduce { state, action in
      switch action {

      case let .credentialsDidChange(newCredentials):
        self.credentials = newCredentials
        return .none

      case .signedInSuccess:
        if case .signedIn = state {
          return .none
        }
        state = .signedIn(SignedInFeature.State())
        return .none

      case .signedOutSuccess:
        self.credentials = nil
        state = .signedOut(SignedOutFeature.State.pending)
        return .none

      case .signedIn:
        return .none

      case .signedOut:
        return .none

      case .view(.onTask):
        let resolvePendingState: Effect<Action>

        // Check for existing Spotify credentials
        if let credentials {
          resolvePendingState = .run { send in
            try await spotify.setExistingCredentials(credentials)
            await send(.signedInSuccess)
          }
        } else {
          state = .signedOut(SignedOutFeature.State.pending)
          resolvePendingState = .none
        }

        // Configure long running tasks for the whole app
        return .merge(
          resolvePendingState,
          .run { send in
            // Subscribe to changes in Spotify credentials, including first sign in success
            for try await credentials in spotify.credentialsDidChange() {
              await send(.credentialsDidChange(credentials))
              await send(.signedInSuccess)
            }
          }
        )

      case .view(.signOutButtonTapped):
        return .run { send in
          try await spotify.signOut()
          await send(.signedOutSuccess)
        }
      }
    }
  }
}

extension URL {
  static let credentials = Self
    .documentsDirectory
    .appending(path: "spotify-credentials.json")
}
