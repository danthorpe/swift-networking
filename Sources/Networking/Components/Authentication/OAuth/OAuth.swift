import AuthenticationServices
import ConcurrencyExtras
import Foundation

// MARK: - Public API

public protocol OAuthSystem: Sendable {
  var authorizationServer: String { get set }
  @available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *)
  var callback: ASWebAuthenticationSession.Callback { get }
  var clientId: String { get }
  var clientSecret: OAuth.ClientSecret { get }
  var scope: String? { get set }
}

public protocol OAuthProxy: Actor {
  func set(presentationContext: any ASWebAuthenticationPresentationContextProviding)
  func authorize(server newService: String?, scope newScopes: String?) async throws
}

extension OAuthProxy {
  public func authorize() async throws {
    try await authorize(server: nil, scope: nil)
  }
}

public enum OAuth { /* Namespace */  }

extension OAuth {
  public enum ClientSecret: Sendable {
    case secret(String)
    case pkce
  }

  public enum Error: Swift.Error, Equatable {
    case oauthNotInstalled
    case invalidAuthorizationService(String)
    case invalidAuthorizationURL(URLComponents)
    //    case webAuthenticationSessionError(any Swift.Error)
  }
}

// MARK: - Implementation Details

// MARK: - Requests etc

// MARK: - Temporary

extension String: Error {}

// MARK: - Conveniences

extension ASWebAuthenticationSession {

  @available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *)
  @MainActor static func start(
    url: URL,
    presentationContext: UncheckedSendable<ASWebAuthenticationPresentationContextProviding>,
    callback: Callback
  ) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      let session = ASWebAuthenticationSession(
        url: url,
        callback: callback,
        completionHandler: handleCallback(continuation: continuation)
      )
      session.presentationContextProvider = presentationContext.value
      session.start()
    }
  }

  @available(iOS, introduced: 12.0, deprecated: 17.4, message: "Use start(url:presentationContext:callback")
  @available(macOS, introduced: 10.15, deprecated: 14.4, message: "Use start(url:presentationContext:callback")
  @available(tvOS, introduced: 12.0, deprecated: 17.4, message: "Use start(url:presentationContext:callback")
  @available(watchOS, introduced: 6.2, deprecated: 10.4, message: "Use start(url:presentationContext:callback")
  @MainActor static func start(
    url: URL,
    presentationContext: UncheckedSendable<ASWebAuthenticationPresentationContextProviding>,
    callbackURLScheme: String?
  ) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      let session = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: callbackURLScheme,
        completionHandler: handleCallback(continuation: continuation)
      )
      session.presentationContextProvider = presentationContext.value
      session.start()
    }
  }

  fileprivate static func handleCallback(
    continuation: CheckedContinuation<URL, any Error>
  ) -> ASWebAuthenticationSession.CompletionHandler {
    { url, error in
      guard let url else {
        if let error {
          print(String(describing: error))
          continuation.resume(throwing: error)
        } else {
          continuation.resume(throwing: "TODO: ASWebAuthentication returned with missing URL and no Error")
        }
        return
      }
      continuation.resume(returning: url)
    }
  }
}

final class DefaultPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
  @MainActor func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    #if os(macOS)
    ASPresentationAnchor()
    #else
    ASPresentationAnchor(frame: CGRect(origin: .zero, size: CGSize(width: 400, height: 400)))
    #endif
  }
}
