//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public protocol Transport {

    func send(request: URLRequest) async throws -> (Data, URLResponse)
}

public extension Transport {

    func send(request: URLRequest) -> Task<(Data, URLResponse), Error> {
        Task { try await send(request: request) }
    }
}
