//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public typealias HTTPResult = Result<HTTPResponse, HTTPError>

public extension HTTPResult {

    var request: HTTPRequest {
        switch self {
        case let .success(response):
            return response.request
        case let .failure(error):
            return error.request
        }
    }

    var response: HTTPResponse? {
        switch self {
        case let .success(response):
            return response
        case let .failure(error):
            return error.response
        }
    }
}
