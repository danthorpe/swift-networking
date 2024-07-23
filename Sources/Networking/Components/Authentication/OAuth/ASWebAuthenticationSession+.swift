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
      let session: ASWebAuthenticationSession
      if #available(iOS 17.4, macOS 14.4, tvOS 17.4, watchOS 10.4, visionOS 1.1, *) {
        session = ASWebAuthenticationSession(
          url: url,
          callback: .customScheme(callbackURLScheme),
          completionHandler: handleCallback(continuation: continuation)
        )
      } else {
        session = ASWebAuthenticationSession(
          url: url,
          callbackURLScheme: callbackURLScheme,
          completionHandler: handleCallback(continuation: continuation)
        )
      }
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
          continuation.resume(
            throwing: ErrorMessage(
              message: "TODO: ASWebAuthentication returned with missing URL and no Error"
            )
          )
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
