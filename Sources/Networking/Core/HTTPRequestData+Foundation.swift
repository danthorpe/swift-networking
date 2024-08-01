import Dependencies
import Foundation
import HTTPTypes
import ShortID

extension HTTPRequestData {

  public init(
    method: HTTPRequest.Method = Defaults.method,
    url: URL,
    headerFields: HTTPFields = [:],
    body: Data? = nil
  ) {
    @Dependency(\.shortID) var shortID
    self.init(
      id: .init(shortID().description),
      body: body,
      request: HTTPRequest(
        method: method,
        url: url,
        headerFields: headerFields
      )
    )
  }
}
