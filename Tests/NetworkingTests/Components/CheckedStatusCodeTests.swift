import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import XCTest

@testable import Networking

final class CheckedStatusCodeTests: XCTestCase {
  
  func configureNetwork(
    for status: HTTPResponse.Status
  ) -> (network: some NetworkingComponent, response: HTTPResponseData) {
    let request = HTTPRequestData(authority: "example.com")
    let stubbed: StubbedResponseStream = .status(status)
    let network = TerminalNetworkingComponent()
      .mocked(request, stub: stubbed)
      .checkedStatusCode()
    
    return (network, stubbed.expectedResponse(request))
  }
  
  func test__ok() async throws {
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      let (network, expectedResponse) = configureNetwork(for: .ok)
      try await network.data(expectedResponse.request)
    }
  }
  
  func test__internal_server_error() async throws {
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      let (network, expectedResponse) = configureNetwork(for: .internalServerError)
      await XCTAssertThrowsError(
        try await network.data(expectedResponse.request),
        matches: StackError.statusCode(expectedResponse)
      )
    }
  }
  
  func test__unauthorized() async throws {
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      let (network, expectedResponse) = configureNetwork(for: .unauthorized)
      await XCTAssertThrowsError(
        try await network.data(expectedResponse.request),
        matches: StackError.unauthorized(expectedResponse)
      )
    }
  }
  
}
