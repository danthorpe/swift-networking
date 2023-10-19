import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import XCTest

@testable import Networking

final class HeaderBasedAuthenticationTests: XCTestCase {
  
  func test__given_requires_credentials__delegate_is_triggered() async throws {
    var request = HTTPRequestData(id: "1")
    request.authenticationMethod = .bearer
    
    let delelgate = TestAuthenticationDelegate(
      fetch: { [request] in
        XCTAssertEqual(request, $0)
        return BearerCredentials(token: "some token")
      }
    )
    
    let authenticator = HeaderBasedAuthentication(delegate: delelgate)
    
    let newRequest = try await authenticator.fetch(for: request).apply(to: request)
    
    XCTAssertEqual(newRequest.headerFields[.authorization], "Bearer some token")
    XCTAssertEqual(delelgate.fetchCount, 1)
  }
  
  func test__given_delegate_throws_error() async throws {
    struct CustomError: Error, Equatable { }
    
    var request = HTTPRequestData(id: "1")
    request.authenticationMethod = .bearer
    
    let delelgate = TestAuthenticationDelegate<BearerCredentials>(
      fetch: { _ in
        throw CustomError()
      }
    )
    
    let authenticator = HeaderBasedAuthentication(delegate: delelgate)
    
    await XCTAssertThrowsError(
      try await authenticator.fetch(for: request),
      matches: AuthenticationError.fetchCredentialsFailed(request, .bearer, CustomError())
    )
  }
  
  func test__requests_are_queued_until_delegate_responds() async throws {
    
    let delelgate = TestAuthenticationDelegate(
      fetch: { _ in
        return BearerCredentials(token: "some token")
      }
    )
    
    let authenticator = HeaderBasedAuthentication(delegate: delelgate)
    
    @Sendable func check(authority: String) async throws -> HTTPRequestData {
      var request = HTTPRequestData(authority: "example.com")
      request.authenticationMethod = .bearer
      return try await authenticator.fetch(for: request).apply(to: request)
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
        XCTAssertEqual(authorization, ["Bearer some token"])
        XCTAssertEqual(delelgate.fetchCount, 1)
      }
    }
  }
}
