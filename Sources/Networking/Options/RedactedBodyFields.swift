import Foundation

/// A `HTTPRequestDataOption` holding the set of body-field keys whose values should be redacted when the
/// request/response body is pretty-printed for logging. Default empty — no redaction. Not part of request
/// equality: it is a logging concern and must not affect identity or caching.
enum RedactedBodyFieldsOption: HTTPRequestDataOption {
  static let defaultOption: Set<String> = []
}

extension HTTPRequestData {
  public var redactedBodyFields: Set<String> {
    get { self[option: RedactedBodyFieldsOption.self] }
    set { self[option: RedactedBodyFieldsOption.self] = newValue }
  }
}
