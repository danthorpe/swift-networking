//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

extension URLSession: Transport {

    @available(iOS 15.0.0, *)
    @available(macOS 12.0, *)
    public func send(request: URLRequest) async throws -> (Data, URLResponse) {
        try await self.data(for: request)
    }

    public func send(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = dataTask(with: request, completionHandler: completion)
        task.resume()
    }
}
