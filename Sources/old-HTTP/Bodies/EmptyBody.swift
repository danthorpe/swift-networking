//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public struct EmptyBody: HTTPBody {

    public let isEmpty = true

    public init() { }

    public func encode() throws -> Data {
        Data()
    }
}
