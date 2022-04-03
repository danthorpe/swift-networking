//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public struct JSONBody: HTTPBody {

    public let isEmpty: Bool = false

    public var additionalHeaders: [String: String] = [
        "Content-Type": "application/json; charset=utf-8"
    ]

    private let _encode: () throws -> Data

    public init<Value: Encodable>(_ value: Value, encoder: JSONEncoder = JSONEncoder()) {
        _encode = { try encoder.encode(value) }
    }

    public func encode() throws -> Data {
        try _encode()
    }
}
