import AssertionExtras
import Dependencies
import Foundation
import Networking
import os.log

package actor RetryingMock {
  package var stubs: [StubbedResponseStream]
  package init(stubs: [StubbedResponseStream]) {
    self.stubs = stubs.reversed()
  }

  package func send(upstream: NetworkingComponent, request: HTTPRequestData) throws -> ResponseStream<
    HTTPResponseData
  > {
    guard let stub = stubs.popLast() else {
      throw RetryMockError(message: "Exhausted supply of stub responses")
    }
    return stub(request)
  }
}

package struct RetryMockError: Error, Equatable {
  package let message: String
}
