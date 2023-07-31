import Foundation

public struct BytesReceived: Sendable, Hashable {
    public internal(set) var bytesReceived: Int64
    public internal(set) var totalBytesReceived: Int64
    public internal(set) var totalBytesExpected: Int64

    public var fractionCompleted: Double {
        max(0.0, min(Double(totalBytesReceived) / Double(totalBytesExpected), 1.0))
    }

    public init(
        bytesReceived: Int64 = 0,
        totalBytesReceived: Int64 = 0,
        totalBytesExpected: Int64 = 0
    ) {
        self.bytesReceived = bytesReceived
        self.totalBytesReceived = totalBytesReceived
        self.totalBytesExpected = totalBytesExpected
    }

    init(data: Data) {
        let count = Int64(data.count)
        self.init(bytesReceived: count, totalBytesReceived: count, totalBytesExpected: count)
    }

    init(response: HTTPResponseData) {
        self.init(data: response.data)
    }

    mutating func receiveBytes(count: Int64) {
        bytesReceived += count
        totalBytesReceived += count
    }

    func withExpectedContentLength(from request: HTTPRequestData) -> BytesReceived {
        BytesReceived(
            bytesReceived: bytesReceived,
            totalBytesReceived: totalBytesReceived,
            totalBytesExpected: max(request.expectedContentLength ?? 0, totalBytesExpected)
        )
    }
}

func + (lhs: BytesReceived, rhs: BytesReceived) -> BytesReceived {
    BytesReceived(
        bytesReceived: lhs.bytesReceived + rhs.bytesReceived,
        totalBytesReceived: lhs.totalBytesReceived + rhs.totalBytesReceived,
        totalBytesExpected: lhs.totalBytesExpected + rhs.totalBytesExpected
    )
}
