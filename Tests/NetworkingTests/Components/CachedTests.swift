import Cache
import CustomDump
import Dependencies
import Foundation
import TestSupport
import Testing

@testable import Networking

@Suite(.tags(.components))
struct CachedTests: TestableNetwork {

  let now = Date()

  @Test func test__basics() async throws {
    let reporter = TestReporter()
    let data = try #require("Hello".data(using: .utf8))
    let cache = Cache<HTTPRequestData, HTTPResponseData>(limit: 3)
    let request = HTTPRequestData(id: "1", path: "message")
    let network = TerminalNetworkingComponent()
      .mocked(request, stub: .ok(data: data))
      .reported(by: reporter)
      .cached(in: cache)

    var response = try await withTestDependencies {
      $0.date = .constant(now)
    } operation: {
      try await network.data(request)
    }
    #expect(response.isCached == false)
    #expect(response.cachedOriginalRequest?.id == nil)
    #expect(String(data: response.data, encoding: .utf8) == "Hello")

    response = try await withTestDependencies {
      $0.date = .constant(now)
    } operation: {
      try await network.data(request)
    }
    #expect(response.isCached)
    #expect(response.cachedOriginalRequest?.id == "1")
    #expect(String(data: response.data, encoding: .utf8) == "Hello")
  }

  @Test func test__never_cache() async throws {
    let reporter = TestReporter()
    var request = HTTPRequestData(id: "1", path: "message")
    request.cacheOption = .never

    let data = try #require("Hello".data(using: .utf8))
    let cache = Cache<HTTPRequestData, HTTPResponseData>(limit: 3)
    let network = TerminalNetworkingComponent()
      .mocked(request, stub: .ok(data: data))
      .reported(by: reporter)
      .cached(in: cache)

    let response1 = try await withTestDependencies {
      try await network.data(request)
    }
    #expect(response1.isCached == false)
    #expect(response1.cachedOriginalRequest?.id == nil)
    #expect(String(data: response1.data, encoding: .utf8) == "Hello")

    let response2 = try await withTestDependencies {
      try await network.data(request)
    }
    #expect(response2.isCached == false)
    #expect(response2.cachedOriginalRequest?.id == nil)
    #expect(String(data: response2.data, encoding: .utf8) == "Hello")

    #expect(response1.request == response2.request)
    #expect(response1 == response2)

    let executedRequestsCount = await reporter.requests.count
    #expect(executedRequestsCount == 2)
  }
}
