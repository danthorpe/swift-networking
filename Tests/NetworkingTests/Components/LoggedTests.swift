import AssertionExtras
import Dependencies
import Foundation
import Networking
import TestSupport
import Testing

@Suite(.tags(.basics))
struct LoggedTests: TestableNetwork {

  struct OnSuccess: Equatable {
    let request: HTTPRequestData
    let response: HTTPResponseData
    let bytes: BytesReceived
  }

  struct OnFailure {
    let request: HTTPRequestData
    let error: Error
  }

  actor LoggedTester {
    var onSend: [HTTPRequestData] = []
    var onSuccess: [OnSuccess] = []
    var onFailure: [OnFailure] = []

    func appendSend(_ value: HTTPRequestData) {
      onSend.append(value)
    }
    func appendSuccess(_ value: OnSuccess) {
      onSuccess.append(value)
    }
    func appendFailure(_ value: OnFailure) {
      onFailure.append(value)
    }
  }

  @Test func test__logged_receives_lifecycle() async throws {

    let tester = LoggedTester()
    let data1 = try #require("Hello".data(using: .utf8))
    let data2 = try #require("World".data(using: .utf8))
    let data3 = try #require("Whoops".data(using: .utf8))

    try await withTestDependencies {
      let request1 = HTTPRequestData(authority: "example.com")
      let request2 = HTTPRequestData(authority: "example.co.uk")
      let request3 = HTTPRequestData(authority: "example.com", path: "error")
      let network = TerminalNetworkingComponent(isFailingTerminal: true)
        .mocked(request1, stub: .ok(data: data1))
        .mocked(request2, stub: .ok(data: data2))
        .mocked(request3, stub: .ok(.throwing, data: data3))
        .logged(using: .test) { [tester] in
          await tester.appendSend($1)
        } onFailure: { [tester] in
          await tester.appendFailure(OnFailure(request: $1, error: $2))
        } onSuccess: { [tester] in
          await tester.appendSuccess(OnSuccess(request: $1, response: $2, bytes: $3))
        }

      try await network.data(request1)
      try await network.data(request2)
      try await network.data(request1)

      await #expect(throws: StubbedNetworkError(request: request3)) {
        try await network.data(request3)
      }

      let requests = await tester.onSend
      #expect(requests == [request1, request2, request1, request3])
      let datas = await tester.onSuccess.map(\.response.data)
      #expect(datas == [data1, data2, data1])
      let failureRequests = await tester.onFailure.map(\.request)
      #expect(failureRequests == [request3])
      let failureErrors = await tester.onFailure.map(\.error)
      #expect(
        failureErrors.compactMap { $0 as? StubbedNetworkError } == [StubbedNetworkError(request: request3)]
      )
    }
  }
}
