import Foundation

public protocol Decoding<Input>: Sendable {
  associatedtype Input: Sendable

  func decode<Body: Decodable>(_ type: Body.Type, from: Input) throws -> Body
}

public protocol Encoding<Output>: Sendable {
  associatedtype Output: Sendable

  func encode<Body: Encodable>(_ value: Body) throws -> Output
}

extension JSONEncoder: Encoding {}
extension JSONDecoder: Decoding {}
extension PropertyListEncoder: Encoding {}
extension PropertyListDecoder: Decoding {}
