import Foundation

public protocol NetworkingError: Error {
  var request: HTTPRequestData { get }
  var response: HTTPResponseData? { get }
}
