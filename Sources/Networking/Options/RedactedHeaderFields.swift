import Foundation
import HTTPTypes

/// A `HTTPRequestDataOption` holding the header names whose values should be redacted when request/response
/// headers are pretty-printed for logging. Unlike `redactedBodyFields` the default is **not** empty: body-field
/// keys are application-specific, whereas `Authorization` carries a credential in every API, so an empty default
/// would leak one for every adopter who never thought to configure this. Not part of request equality: it is a
/// logging concern and must not affect identity or caching.
enum RedactedHeaderFieldsOption: HTTPRequestDataOption {
  static let defaultOption: Set<HTTPField.Name> = [
    .authorization,
    .proxyAuthorization,
    .cookie,
    .setCookie,
  ]
}

extension HTTPRequestData {
  public var redactedHeaderFields: Set<HTTPField.Name> {
    get { self[option: RedactedHeaderFieldsOption.self] }
    set { self[option: RedactedHeaderFieldsOption.self] = newValue }
  }
}
