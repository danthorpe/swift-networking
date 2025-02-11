import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.components))
struct CheckedStatusCodeTests: TestableNetwork {

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

  @Test func test__ok() async throws {
    try await withTestDependencies {
      let (network, expectedResponse) = configureNetwork(for: .ok)
      try await network.data(expectedResponse.request)
    }
  }

  @Test func test__internal_server_error() async throws {
    try await withTestDependencies {
      let (network, expectedResponse) = configureNetwork(for: .internalServerError)
      try await #expect(throws: StackError(statusCode: expectedResponse)) {
        try await network.data(expectedResponse.request)
      }
    }
  }

  @Test func test__unauthorized() async throws {
    try await withTestDependencies {
      let (network, expectedResponse) = configureNetwork(for: .unauthorized)
      try await #expect(throws: StackError(unauthorized: expectedResponse)) {
        try await network.data(expectedResponse.request)
      }
    }
  }
}
