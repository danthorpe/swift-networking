//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public protocol HTTPBody {

    var isEmpty: Bool { get }

    var additionalHeaders: [String: String] { get }

    func encode() throws -> Data
}

public extension HTTPBody {

    var isEmpty: Bool { false }

    var additionalHeaders: [String: String] { [:] }
}
