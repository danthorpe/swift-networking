import Foundation

public struct EmptyBody: HTTPRequestBody {
  public let isEmpty = true
  public init() { }
  public func encode() throws -> Data {
    Data()
  }
}
