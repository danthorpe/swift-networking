//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Concurrency
import Foundation

public final class ResetGuard: HTTPLoadable {

    @Protected private var isResetting = false

    public func load(_ request: HTTPRequest) async throws -> HTTPLoadableResponse {
        guard false == isResetting else {
            throw HTTPError(.resetInProgress, request: request)
        }
        return .continue
    }

//    public func reset() async {
//        guard false == isResetting, let next = next else { return }
//        isResetting = true
//        await next.reset()
//        self.isResetting = false
//    }
}
