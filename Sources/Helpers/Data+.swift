import Foundation

extension Data {

  /// Bodies larger than this are summarised rather than decoded for logging.
  public static let prettyPrintedByteLimit = 8_192

  /// A description of the data suitable for logging.
  ///
  /// Binary bodies are summarised rather than decoded — an image upload would otherwise become
  /// megabytes of replacement characters, built eagerly whether or not the log is being collected.
  /// Textual bodies past `maxBytes` are summarised for the same reason.
  ///
  /// - Parameters:
  ///   - keys: body-field keys whose values should be redacted.
  ///   - contentType: the body's media type, if known. A `nil` type is treated as textual, in
  ///   which case only `maxBytes` protects the log.
  ///   - maxBytes: the largest textual body to decode.
  public func prettyPrintedData(
    redacting keys: Set<String> = [],
    contentType: String? = nil,
    maxBytes: Int = Data.prettyPrintedByteLimit
  ) -> String {
    guard isNotEmpty else { return "Empty data" }
    guard contentType.map(Data.isTextualContentType) ?? true else {
      return "<\(count) bytes of \(contentType ?? "unknown content")>"
    }
    guard count <= maxBytes else {
      return "<\(count) bytes, too large to log>"
    }
    guard keys.isNotEmpty else { return String(decoding: self, as: UTF8.self) }

    // Structured JSON (objects/arrays, recursive).
    if let json = try? JSONSerialization.jsonObject(with: self, options: [.fragmentsAllowed]),
      json is [String: Any] || json is [Any],
      let redacted = try? JSONSerialization.data(
        withJSONObject: Data.redact(json, keys: keys),
        options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
      )
    {
      return String(decoding: redacted, as: UTF8.self)
    }

    // Form-urlencoded.
    let string = String(decoding: self, as: UTF8.self)
    if string.contains("=") {
      return
        string
        .split(separator: "&", omittingEmptySubsequences: false)
        .map { pair -> String in
          let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
          guard parts.count == 2, keys.contains(String(parts[0])) else { return String(pair) }
          return "\(parts[0])=<redacted>"
        }
        .joined(separator: "&")
    }

    return string
  }

  /// Whether a media type describes something worth decoding into the log.
  private static func isTextualContentType(_ contentType: String) -> Bool {
    // Media types carry parameters — "application/json; charset=utf-8".
    let type = contentType
      .split(separator: ";", maxSplits: 1)
      .first
      .map { $0.trimmingCharacters(in: .whitespaces).lowercased() } ?? ""

    if type.hasPrefix("text/") { return true }
    if type.hasSuffix("+json") || type.hasSuffix("+xml") { return true }

    return [
      "application/json",
      "application/xml",
      "application/x-www-form-urlencoded",
      "application/javascript",
      "application/graphql",
    ]
    .contains(type)
  }

  private static func redact(_ value: Any, keys: Set<String>) -> Any {
    switch value {
    case let dict as [String: Any]:
      var out: [String: Any] = [:]
      for (key, nested) in dict {
        out[key] = keys.contains(key) ? "<redacted>" : redact(nested, keys: keys)
      }
      return out
    case let array as [Any]:
      return array.map { redact($0, keys: keys) }
    default:
      return value
    }
  }
}
