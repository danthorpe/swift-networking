import Foundation
import HTTPTypes

public struct DataBody: HTTPRequestBody {
    private let data: Data
    public let additionalHeaders: HTTPFields

    public var isEmpty: Bool { data.isEmpty }

    public init(data: Data, additionalHeaders: HTTPFields) {
        self.data = data
        self.additionalHeaders = additionalHeaders
    }

    public func encode() throws -> Data {
        data
    }
}
