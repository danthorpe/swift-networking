import Foundation
import HTTPTypes

public struct JSONBody: HTTPRequestBody {
  public let isEmpty = false
  public var additionalHeaders: HTTPFields = [
    .contentType: "application/json; charset=utf-8"
  ]
  private let _encode: () throws -> Data
  public init<Body: Encodable>(_ value: Body, encoder: JSONEncoder = JSONEncoder()) {
    _encode = { try encoder.encode(value) }
  }

  public func encode() throws -> Data {
    try _encode()
  }
}
