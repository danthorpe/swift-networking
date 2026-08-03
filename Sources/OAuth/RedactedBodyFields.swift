import Foundation

extension OAuth {
  /// Body-field keys that carry OAuth secrets across token exchange and refresh — redacted from logged
  /// request/response bodies. Set on every token request via `redactedBodyFields`.
  public static let redactedBodyFields: Set<String> = [
    "access_token",
    "refresh_token",
    "id_token",
    "code",
    "code_verifier",
    "client_secret",
  ]
}
