import Dependencies
import Foundation
import Networking
import ShortID
import TestSupport
import Testing

@Suite(.tags(.basics))
struct NetworkingComponentValueTests: TestableNetwork {
  let json =
    """
    {"value":"Hello World"}
    """

  @Test func test__decoder_basics_with_request() async throws {
    let data = try #require(json.data(using: .utf8))

    let network = TerminalNetworkingComponent()
      .mocked(all: .ok(data: data))

    let (message, response) = try await withTestDependencies {
      let request = HTTPRequestData(authority: "example.com")
      return try await network.value(Request<Message>(http: request))
    }

    #expect(message.value == "Hello World")
    #expect(response.status == .ok)
  }

  @Test func test__decoder_basics_with_decoder() async throws {
    let data = try #require(json.data(using: .utf8))

    let network = TerminalNetworkingComponent()
      .mocked(all: .ok(data: data))

    let (message, response) = try await withTestDependencies {
      let request = HTTPRequestData(authority: "example.com")
      return try await network.value(request, as: Message.self, decoder: JSONDecoder())
    }

    #expect(message.value == "Hello World")
    #expect(response.status == .ok)
  }
}

private struct Message: Decodable, Equatable {
  let value: String
}
