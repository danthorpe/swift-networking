// Copied from swift-composable-architecture

public func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
  (lhs as? any Equatable)?.isEqual(other: rhs) ?? false
}

extension Equatable {
  fileprivate func isEqual(other: Any) -> Bool {
    self == other as? Self
  }
}
