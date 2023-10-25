import Foundation

extension Optional where Wrapped: RangeReplaceableCollection {
  public mutating func append(_ newElement: Wrapped.Element, default defaultValue: Wrapped) {
    switch self {
    case var .some(this):
      this.append(newElement)
      self = .some(this)
    case .none:
      var copy = defaultValue
      copy.append(newElement)
      self = .some(copy)
    }
  }
}

extension Optional where Wrapped: RangeReplaceableCollection, Wrapped: ExpressibleByArrayLiteral {
  public mutating func append(_ newElement: Wrapped.Element) {
    append(newElement, default: [])
  }
}
