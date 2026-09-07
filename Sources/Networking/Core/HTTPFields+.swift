import Foundation
import HTTPTypes

extension HTTPFields {
  /// A description of the fields suitable for logging.
  ///
  /// - Parameters:
  ///   - title: the heading the fields are listed under.
  ///   - names: header names whose values should be redacted. The name itself is still printed, so a
  ///   trace remains diagnostic — you can see that auth was sent without seeing the credential.
  func prettyPrintedDescription(
    title: String,
    redacting names: Set<HTTPField.Name> = []
  ) -> String {
    reduce(title) { partialResult, field in
      let value = names.contains(field.name) ? "<redacted>" : field.value
      return """
        \(partialResult)
        \(field.name): \(value)
        """
    }
  }
}
