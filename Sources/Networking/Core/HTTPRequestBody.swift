import Foundation
import HTTPTypes

public protocol HTTPRequestBody {
  var isEmpty: Bool { get }
  var additionalHeaders: HTTPFields { get }
  func encode() throws -> Data
}

extension HTTPRequestBody {
  public var isEmpty: Bool { false }
  public var isNotEmpty: Bool { false == isEmpty }
  public var additionalHeaders: HTTPFields { [:] }
}

extension HTTPFields {
  mutating func append(_ other: Self) {
    for field in other {
      self[fields: field.name].append(field)
    }
  }
}
