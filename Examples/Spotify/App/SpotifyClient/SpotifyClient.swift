import AuthenticationServices
import Dependencies
import DependenciesMacros
import NetworkClient
import Networking
import OAuth
import os.log

struct Spotify {
  @DependencyClient
  struct Client: Sendable {
    var credentialsDidChange: @Sendable () -> AsyncThrowingStream<OAuth.AvailableSystems.Spotify.Credentials, Error> = {
      AsyncThrowingStream.never
    }
    var followedArtists: @Sendable (_ after: String?, _ limit: Int?) async throws -> Artists
    var me: @Sendable () async throws -> User
    var setExistingCredentials: @Sendable (OAuth.AvailableSystems.Spotify.Credentials) async throws -> Void
    var signIn:
      @Sendable (_ presentationContext: (any ASWebAuthenticationPresentationContextProviding)?) async throws -> Void
    var signOut: @Sendable () async throws -> Void

    func followedArtists(after cursor: String? = nil) async throws -> Artists {
      try await followedArtists(after: cursor, limit: 10)
    }
  }
}

extension DependencyValues {
  var spotify: Spotify.Client {
    get { self[Spotify.Client.self] }
    set { self[Spotify.Client.self] = newValue }
  }
}

extension Spotify {
  static let api: any NetworkingComponent = {
    @Dependency(\.networkClient.network) var networkClient
    return networkClient()
      .logged(using: Logger(subsystem: "works.dan.networking.examples.spotify", category: "Spotify API"))
      .server(prefixPath: "v1")
      .server(authority: "api.spotify.com")
      .authenticated(
        oauth: .spotify(
          clientId: "b4937bc99da547b4b90559f5024d8467",
          callback: "swift-networking-spotify-example://callback",
          scope: "user-read-email user-read-private user-follow-read"
        )
      )
  }()
  static let decoder: JSONDecoder = {
    var decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()
}

extension Spotify.Client: DependencyKey {
  static let liveValue = Spotify.Client(
    credentialsDidChange: {
      AsyncThrowingStream { continuation in
        Task {
          do {
            try await Spotify.api.spotify {
              await $0.subscribeToCredentialsDidChange { credentials in
                continuation.yield(credentials)
              }
            }
          } catch {
            continuation.finish(throwing: error)
          }
        }
      }
      .shared()
      .eraseToThrowingStream()
    },
    followedArtists: { after, limit in
      try await Spotify.api
        .value(
          .followedArtists(
            after: after,
            limit: limit
          )
        )
        .body
    },
    me: {
      try await Spotify.api.value(.me).body
    },
    setExistingCredentials: { existingCredentials in
      try await Spotify.api.spotify {
        await $0.set(credentials: existingCredentials)
      }
    },
    signIn: { context in
      try await Spotify.api.spotify {
        if let context {
          await $0.set(presentationContext: context)
        }
        try await $0.signIn()
      }
    },
    signOut: {
      try await Spotify.api.spotify {
        await $0.signOut()
      }
    }
  )
}
