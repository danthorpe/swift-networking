import AuthenticationServices
import ConcurrencyExtras
import Helpers

// MARK: - Conveniences

extension ASWebAuthenticationSession {

  @MainActor static func start(
    url: URL,
    presentationContext: UncheckedSendable<ASWebAuthenticationPresentationContextProviding>,
    callbackURLScheme: String
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
          continuation.resume(throwing: error)
        } else {
          continuation.resume(
            throwing: ErrorMessage(
              message: "ASWebAuthentication returned with missing URL and no Error"
            )
          )
        }
        return
      }
      continuation.resume(returning: url)
    }
  }
}

@MainActor public final class DefaultPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    #if os(macOS)
    ASPresentationAnchor()
    #else
    ASPresentationAnchor(frame: CGRect(origin: .zero, size: CGSize(width: 400, height: 400)))
    #endif
  }
}
