import AuthenticationServices
import ConcurrencyExtras
import Dependencies
import Helpers
import Networking
import Protected

// MARK: - OAuth Installed Systems

extension OAuth {
  struct InstalledSystems: Sendable {

    static func oauth<Credentials: BearerAuthenticatingCredentials>(
      as credentials: Credentials.Type
    ) -> OAuth.Proxy<Credentials>? {
      Self.current.value.get(key: Credentials.self)
    }

    static func set<Credentials: BearerAuthenticatingCredentials>(
      oauth proxy: OAuth.Proxy<Credentials>
    ) {
      Self.current.withValue {
        $0.storage[ObjectIdentifier(Credentials.self)] = AnySendable(proxy)
      }
    }

    static var current = LockIsolated(Self())

    private var storage: [ObjectIdentifier: AnySendable] = [:]

    private func get<Credentials: BearerAuthenticatingCredentials>(
      key: Credentials.Type
    ) -> OAuth.Proxy<Credentials>? {
      guard
        let base = self.storage[ObjectIdentifier(key)]?.base,
        let value = base as? OAuth.Proxy<Credentials>
      else { return nil }
      return value
    }
  }
}
