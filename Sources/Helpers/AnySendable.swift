import Foundation

package struct AnySendable: @unchecked Sendable {
  package let base: Any
  package init<Base: Sendable>(_ base: Base) {
    self.base = base
  }
}
