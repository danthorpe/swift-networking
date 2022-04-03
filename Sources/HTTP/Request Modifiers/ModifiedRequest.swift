//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

open class ModifiedRequest: HTTPLoader_ {
    public typealias Modifier = (HTTPRequest) -> HTTPRequest

    private let modifier: Modifier

    public init(_ modifier: @escaping Modifier) {
        self.modifier = modifier
    }

    public override func load(request: HTTPRequest) async throws -> HTTPResponse {
        try await super.load(request: modifier(request))
    }
}
