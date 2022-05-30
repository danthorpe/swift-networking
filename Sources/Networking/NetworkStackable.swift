//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation
import URLRouting

public protocol NetworkStackable {

    func send(_ request: URLRequestData) async throws -> URLResponseData

    /// Perform any clean-up to clear any state
    func reset() async

    /// Perform any clean-up after cancellation for an in-flight loadable
    func didCancel()
}


/// Default Implementations
public extension NetworkStackable {

    func reset() async { }

    func didCancel() { }
}
