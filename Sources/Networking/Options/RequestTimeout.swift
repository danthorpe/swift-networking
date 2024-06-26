import Foundation

enum RequestTimeoutInSeconds: HTTPRequestDataOption {
  static let defaultOption: Int64 = 60
}

extension HTTPRequestData {
  public var requestTimeoutInSeconds: Int64 {
    get { self[option: RequestTimeoutInSeconds.self] }
    set { self[option: RequestTimeoutInSeconds.self] = newValue }
  }
}
