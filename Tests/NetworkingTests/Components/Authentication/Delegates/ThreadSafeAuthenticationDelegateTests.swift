import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.authentication))
struct ThreadSafeAuthenticationDelegateTests {

  @Test func test__given_authorize__delegate_is_triggered() async throws {
    var request = HTTPRequestData(id: "1")
    request.authenticationMethod = .bearer

    let delelgate = TestAuthenticationDelegate(
      authorize: {
        BearerCredentials(token: "some token")
      }
    )

    let authenticator = ThreadSafeAuthenticationDelegate(
      delegate: delelgate
    )

    let newRequest = try await authenticator.authorize().apply(to: request)

    #expect(newRequest.headerFields[.authorization] == "Bearer some token")
    let authorizeCount = await delelgate.authorizeCount
    #expect(authorizeCount == 1)
  }

  @Test func test__given_delegate_throws_error() async throws {
    struct CustomError: Error, Equatable {}

    var request = HTTPRequestData(id: "1")
    request.authenticationMethod = .bearer

    let delelgate = TestAuthenticationDelegate<BearerCredentials>(
      authorize: {
        throw CustomError()
      }
    )

    let authenticator = ThreadSafeAuthenticationDelegate(
      delegate: delelgate
    )

    try await #require(
      performing: {
        try await authenticator.fetch(for: request)
      },
      throws: {
        $0 is CustomError
      })
  }

  @Test func test__requests_are_queued_until_delegate_responds() async throws {

    let delelgate = TestAuthenticationDelegate(
      authorize: {
        BearerCredentials(token: "some token")
      }
    )

    let authenticator = ThreadSafeAuthenticationDelegate(
      delegate: delelgate
    )

    @Sendable func check(authority: String) async throws -> HTTPRequestData {
      var request = HTTPRequestData(authority: "example.com")
      request.authenticationMethod = .bearer
      return try await authenticator.authorize().apply(to: request)
    }

    try await withDependencies {
      $0.shortID = .incrementing
    } operation: {
      try await withMainSerialExecutor {
        let requests = try await withThrowingTaskGroup(of: HTTPRequestData.self) { group in
          group.addTask {
            try await check(authority: "example.com")
          }
          group.addTask {
            try await check(authority: "example.co.uk")
          }
          group.addTask {
            try await check(authority: "example.fr")
          }
          group.addTask {
            try await check(authority: "example.com")
          }

          var requests: [HTTPRequestData] = []
          for try await request in group {
            requests.append(request)
          }
          return requests
        }

        let authorization = Set(requests.compactMap(\.headerFields[.authorization]))
        let authorizeCount = await delelgate.authorizeCount
        #expect(authorization == ["Bearer some token"])
        #expect(authorizeCount == 1)
      }
    }
  }
}
