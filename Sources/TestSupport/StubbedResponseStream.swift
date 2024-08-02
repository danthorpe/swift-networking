import Clocks
import Foundation
import HTTPTypes

@testable import Networking

public struct StubbedResponseStream: Equatable, Sendable {
  public enum Configuration: Equatable, Sendable {
    case immediate
    case uniform(steps: Int = 4, interval: Duration = .seconds(2))
    case throwing

    public static let `default`: Self = .uniform()
  }

  public let configuration: Configuration
  public let data: Data
  public let response: HTTPResponse

  public init(
    _ configuration: Configuration = .default,
    data: Data = Data(),
    response: HTTPResponse
  ) {
    self.configuration = configuration
    self.data = data
    self.response = response
  }

  public func callAsFunction(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    ResponseStream { continuation in
      let responseData = expectedResponse(request)
      Task {
        let clock = TestClock()
        var bytes = BytesReceived().withExpectedBytes(from: responseData)
        switch configuration {
        case .immediate:
          bytes.receiveBytes(count: Int64(responseData.data.count))
          continuation.yield(.value(responseData, bytes))
          continuation.finish()
        case .throwing:
          let bytesReceived = bytes.expected / 4
          for _ in 0 ..< 2 {
            await clock.advance(by: .seconds(2))
            bytes.receiveBytes(count: bytesReceived)
            continuation.yield(.progress(bytes))
          }
          continuation.finish(throwing: StubbedNetworkError(request: request))

        case let .uniform(steps: steps, interval: interval):
          let bytesReceived = bytes.expected / Int64(steps)
          for _ in 0 ..< steps {
            await clock.advance(by: interval)
            bytes.receiveBytes(count: bytesReceived)
            continuation.yield(.progress(bytes))
          }
          continuation.yield(.value(responseData, BytesReceived(response: responseData)))
          continuation.finish()
        }
      }
    }
  }

  public func expectedResponse(_ request: HTTPRequestData) -> HTTPResponseData {
    guard
      let url = request.url,
      let httpUrlResponse = HTTPURLResponse(httpResponse: response, url: url)
    else { fatalError("Unable to create HTTPURLResponse from \(response) and \(String(describing: request.url))") }
    return HTTPResponseData(request: request, data: data, httpUrlResponse: httpUrlResponse, httpResponse: response)
  }
}

extension StubbedResponseStream {
  public static func ok(
    _ configuration: Configuration = .default,
    body: any HTTPRequestBody,
    headerFields: HTTPFields = [:]
  ) throws -> Self {
    try .ok(configuration, data: body.encode(), headerFields: headerFields + body.additionalHeaders)
  }

  public static func ok(
    _ configuration: Configuration = .default,
    data: Data = Data(),
    headerFields: HTTPFields = [:]
  ) -> Self {
    .status(.ok, configuration, data: data, headerFields: headerFields)
  }

  public static func status(
    _ status: HTTPResponse.Status,
    _ configuration: Configuration = .default,
    data: Data = Data(),
    headerFields: HTTPFields = [:]
  ) -> Self {
    .init(configuration, data: data, response: .init(status: status, headerFields: headerFields))
  }
}
