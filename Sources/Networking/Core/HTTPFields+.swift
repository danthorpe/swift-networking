import Foundation
import HTTPTypes

extension HTTPFields {
  func prettyPrintedDescription(title: String) -> String {
    reduce(title) { partialResult, field in
      """
      \(partialResult)
      \(field.name): \(field.value)
      """
    }
  }
}
