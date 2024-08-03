import AuthenticationServices
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct WebAuthenticationSessionClient {
  var start:
    @MainActor (
      _ state: String,
      _ authorizationURL: URL,
      _ presentationContext: UncheckedSendable<ASWebAuthenticationPresentationContextProviding>,
      _ callbackURLScheme: String
    ) async throws -> URL
}

extension WebAuthenticationSessionClient: DependencyKey {
  static let liveValue = WebAuthenticationSessionClient { _, authorizationURL, context, callback in
    try await ASWebAuthenticationSession.start(
      url: authorizationURL,
      presentationContext: context,
      callbackURLScheme: callback
    )
  }
}

extension DependencyValues {
  var webAuthenticationSession: WebAuthenticationSessionClient {
    get { self[WebAuthenticationSessionClient.self] }
    set { self[WebAuthenticationSessionClient.self] = newValue }
  }
}
