import AuthenticationServices

public protocol OAuthProxy: Actor {
  func set(presentationContext: any ASWebAuthenticationPresentationContextProviding)
  func authorize() async throws
}
