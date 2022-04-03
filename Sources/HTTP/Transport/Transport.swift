//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public protocol Transport {

    @available(iOS 15.0.0, *)
    @available(macOS 12.0, *)
    func send(request: URLRequest) async throws -> (Data, URLResponse)

    func send(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}
