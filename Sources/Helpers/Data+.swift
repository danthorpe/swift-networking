import Foundation

extension Data {
  public func prettyPrintedData(redacting keys: Set<String> = []) -> String {
    guard isNotEmpty else { return "Empty data" }
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
