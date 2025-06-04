import AuthenticationServices
import ConcurrencyExtras
import Dependencies
import DependenciesMacros
import Helpers
import Networking
import Protected

// MARK: - OAuth Installed Systems

extension OAuth {
  struct Container: Sendable {
    let key: ObjectIdentifier
    let proxy: AnySendable
    init<Credentials: OAuthCredentials>(proxy: some OAuthProxy<Credentials>) {
      self.key = ObjectIdentifier(Credentials.self)
      self.proxy = AnySendable(proxy)
    }
  }

  @DependencyClient
  public struct InstalledSystems: Sendable {
    var set: @Sendable (_ container: Container) -> Void
    var get: @Sendable (_ key: ObjectIdentifier) -> Container?
    var remove: @Sendable (_ key: ObjectIdentifier) -> Void
    var removeAll: @Sendable () -> Void

    func set<Credentials: OAuthCredentials>(oauth proxy: some OAuthProxy<Credentials>) {
      self.set(Container(proxy: proxy))
    }

    func remove<Credentials: OAuthCredentials>(system: Credentials.Type) {
      remove(ObjectIdentifier(Credentials.self))
    }

    func oauth<Credentials: OAuthCredentials>(as credentials: Credentials.Type) -> (any OAuthProxy<Credentials>)? {
      (get(ObjectIdentifier(Credentials.self))?.proxy.base as? any OAuthProxy<Credentials>)
    }
  }
}

extension OAuth.InstalledSystems: DependencyKey {
  public static let testValue = OAuth.InstalledSystems()

  public static func basic() -> Self {
    let storage = LockIsolated<[ObjectIdentifier: OAuth.Container]>([:])
    return OAuth.InstalledSystems(
      set: { container in
        storage.withValue { value in
          value[container.key] = container
        }
      },
      get: { key in
        storage.withValue { value in
          value[key]
        }
      },
      remove: { key in
        storage.withValue { value in
          value[key] = nil
        }
      },
      removeAll: {
        storage.setValue([:])
      }
    )
  }

  public static let liveValue = OAuth.InstalledSystems.basic()
}

extension DependencyValues {
  public var oauthSystems: OAuth.InstalledSystems {
    get { self[OAuth.InstalledSystems.self] }
    set { self[OAuth.InstalledSystems.self] = newValue }
  }
}
