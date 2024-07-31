import AssertionExtras
import ConcurrencyExtras
import Dependencies
import Foundation
import HTTPTypes
import Networking
import TestSupport
import XCTest

final class AuthenticationTests: XCTestCase {

  override func invokeTest() {
    withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      super.invokeTest()
    }
  }

  func test__authentication() async throws {
    let reporter = TestReporter()
    let delegate = TestAuthenticationDelegate(
      authorize: {
        BearerCredentials(token: "token")
      }
    )

    var request = HTTPRequestData(authority: "example.com")
    request.authenticationMethod = .bearer
    let copy = request

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .authenticated(withBearer: delegate)

    try await withMainSerialExecutor {
      try await withThrowingTaskGroup(of: HTTPResponseData.self) { group in

        for _ in 0 ..< 4 {
          group.addTask {
            try await network.data(copy)
          }
        }

        var responses: [HTTPResponseData] = []
        for try await response in group {
          responses.append(response)
        }
        XCTAssertTrue(
          responses.allSatisfy {
            $0.request.headerFields[.authorization] == "Bearer token"
          })
      }

      let reportedRequests = await reporter.requests
      XCTAssertEqual(reportedRequests.count, 4)
      XCTAssertTrue(
        reportedRequests.allSatisfy {
          $0.headerFields[.authorization] == "Bearer token"
        })

      let authorizeCount = await delegate.authorizeCount
      XCTAssertEqual(authorizeCount, 1)
    }
  }

  func test__authentication__when_delegate_throws_error_on_fetch() async throws {
    struct CustomError: Error, Hashable {}

    let delegate = TestAuthenticationDelegate<BearerCredentials>(
      authorize: {
        throw CustomError()
      }
    )

    var request = HTTPRequestData(authority: "example.com")
    request.authenticationMethod = .bearer

    let network = TerminalNetworkingComponent()
      .authenticated(withBearer: delegate)

    await XCTAssertThrowsError(
      try await network.data(request),
      matches: AuthenticationError.fetchCredentialsFailed(request, .bearer, CustomError())
    )
  }

  func test__authentication__refresh_token() async throws {

    let isUnauthorized = LockIsolated(true)
    let reporter = TestReporter()
    let delegate = TestAuthenticationDelegate(
      authorize: {
        BearerCredentials(token: "token")
      },
      refresh: { _, _ in
        BearerCredentials(token: "refreshed token")
      }
    )

    var request = HTTPRequestData(authority: "example.com")
    request.authenticationMethod = .bearer

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .mocked(
        .status(.unauthorized),
        check: { _ in
          defer {
            isUnauthorized.withValue { $0.toggle() }
          }
          return isUnauthorized.value
        }
      )
      .reported(by: reporter)
      .authenticated(withBearer: delegate)

    try await network.data(request)

    let reportedRequests = await reporter.requests
    let authorizeCount = await delegate.authorizeCount
    let refreshCount = await delegate.refreshCount
    XCTAssertEqual(reportedRequests.count, 2)
    XCTAssertTrue(reportedRequests[0].headerFields[.authorization] == "Bearer token")
    XCTAssertTrue(reportedRequests[1].headerFields[.authorization] == "Bearer refreshed token")
    XCTAssertEqual(authorizeCount, 1)
    XCTAssertEqual(refreshCount, 1)
  }
}
