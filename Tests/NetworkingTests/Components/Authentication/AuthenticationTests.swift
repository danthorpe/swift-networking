import AssertionExtras
import ConcurrencyExtras
import Dependencies
import Foundation
import HTTPTypes
import Networking
import TestSupport
import Testing

@Suite(.tags(.authentication))
struct AuthenticationTests: TestableNetwork {

  @Test func test__authentication() async throws {
    let reporter = TestReporter()
    let delegate = TestAuthenticationDelegate(
      authorize: {
        BearerCredentials(token: "token")
      }
    )

    let network = TerminalNetworkingComponent()
      .mocked(.ok(), check: { _ in true })
      .reported(by: reporter)
      .authenticated(withBearer: delegate)

    try await withTestDependencies {
      var request = HTTPRequestData(authority: "example.com")
      request.authenticationMethod = .bearer
      let copy = request

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
          #expect(
            responses.allSatisfy {
              $0.request.headerFields[.authorization] == "Bearer token"
            })
        }

        let reportedRequests = await reporter.requests
        #expect(reportedRequests.count == 4)
        #expect(
          reportedRequests.allSatisfy {
            $0.headerFields[.authorization] == "Bearer token"
          })

        let authorizeCount = await delegate.authorizeCount
        #expect(authorizeCount == 1)
      }
    }
  }

  @Test func test__authentication__when_delegate_throws_error_on_fetch() async throws {
    struct CustomError: Error, Hashable {}

    let delegate = TestAuthenticationDelegate<BearerCredentials>(
      authorize: {
        throw CustomError()
      }
    )

    let network = TerminalNetworkingComponent()
      .authenticated(withBearer: delegate)

    await withTestDependencies {
      var request = HTTPRequestData(authority: "example.com")
      request.authenticationMethod = .bearer

      await #expect(throws: AuthenticationError.fetchCredentialsFailed(request, .bearer, CustomError())) {
        try await network.data(request)
      }
    }
  }

  @Test func test__authentication__refresh_token() async throws {
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

    try await withTestDependencies {
      var request = HTTPRequestData(authority: "example.com")
      request.authenticationMethod = .bearer
      try await network.data(request)
    }

    let reportedRequests = await reporter.requests
    let authorizeCount = await delegate.authorizeCount
    let refreshCount = await delegate.refreshCount
    #expect(reportedRequests.count == 2)
    #expect(reportedRequests[0].headerFields[.authorization] == "Bearer token")
    #expect(reportedRequests[1].headerFields[.authorization] == "Bearer refreshed token")
    #expect(authorizeCount == 1)
    #expect(refreshCount == 1)
  }
}
