import Foundation

extension Data {
  public var prettyPrintedData: String {
    guard self.isNotEmpty else { return "Empty data" }
    return String(decoding: self, as: UTF8.self)
  }
}
