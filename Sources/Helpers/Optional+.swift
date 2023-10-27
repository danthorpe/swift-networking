import Foundation

extension Optional where Wrapped: Collection {
  public var isEmptyOrNil: Bool {
    self?.isEmpty ?? true
  }
  public var isNotEmptyNorNil: Bool {
    false == isEmptyOrNil
  }
}
