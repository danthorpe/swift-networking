import Foundation

package struct ErrorMessage: Error, Equatable, ExpressibleByStringLiteral {
  let message: String
  package init(message: String) {
    self.message = message
  }
  package init(stringLiteral value: String) {
    self.init(message: value)
  }
}
