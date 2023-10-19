import Foundation

public struct BytesReceived: Sendable, Hashable {
  public internal(set) var received: Int64
  public internal(set) var expected: Int64

  public var fractionCompleted: Double {
    max(0.0, min(Double(received) / Double(expected), 1.0))
  }

  public init(
    received: Int64 = 0,
    expected: Int64 = 0
  ) {
    self.received = received
    self.expected = expected
  }

  public init(data: Data) {
    let count = Int64(data.count)
    self.init(received: count, expected: count)
  }

  public mutating func receiveBytes(count: Int64) {
    received += count
  }

  public func withExpectedContentLength(from request: HTTPRequestData) -> BytesReceived {
    BytesReceived(
      received: received,
      expected: max(request.expectedContentLength ?? 0, expected)
    )
  }

  public func withExpectedBytes(from response: HTTPResponseData) -> BytesReceived {
    BytesReceived(
      received: received,
      expected: max(Int64(response.data.count), expected)
    )
  }
}

func + (lhs: BytesReceived, rhs: BytesReceived) -> BytesReceived {
  BytesReceived(
    received: lhs.received + rhs.received,
    expected: lhs.expected + rhs.expected
  )
}
