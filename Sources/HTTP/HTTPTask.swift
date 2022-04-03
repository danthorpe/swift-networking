//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public class HTTPTask {

    public internal(set) var request: HTTPRequest

    public var id: UUID { request.id }

    public init(request: HTTPRequest) {
        self.request = request
    }
}
