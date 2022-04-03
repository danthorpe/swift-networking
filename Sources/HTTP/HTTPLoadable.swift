//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public enum HTTPLoadableResponse {
    case `continue`
    case end(HTTPResponse)
}

public protocol HTTPLoadable {

    func load(_ request: HTTPRequest) async throws -> HTTPLoadableResponse
}
