//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public struct DataBody: HTTPBody {

    private let data: Data

    public var additionalHeaders: [String : String]

    public var isEmpty: Bool { data.isEmpty }

    public init(_ data: Data, additionalHeaders: [String : String] = [:]) {
        self.data = data
        self.additionalHeaders = additionalHeaders
    }

    public func encode() throws -> Data {
        data
    }
}
