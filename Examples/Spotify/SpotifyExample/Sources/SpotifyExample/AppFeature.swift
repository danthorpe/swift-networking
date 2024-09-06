import ComposableArchitecture
import Foundation
import OAuth
import SignedIn
import SignedOut
import SpotifyClient

@Reducer
struct AppFeature {

  @ObservableState
  enum State {
    case pending
    case signedOut(SignedOutFeature.State)
    case signedIn(SignedInFeature.State)
  }

  enum Action {
    case credentialsDidChange(OAuth.AvailableSystems.Spotify.Credentials)
    case signedInSuccess
    case view(View)
    case signedIn(SignedInFeature.Action)
    case signedOut(SignedOutFeature.Action)

    enum View {
      case onTask
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
      }
    }
  }
}

extension URL {
  static let credentials = Self
    .documentsDirectory
    .appending(path: "spotify-credentials.json")
}
