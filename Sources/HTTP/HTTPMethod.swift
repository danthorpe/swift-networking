//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

public struct HTTPMethod: Hashable {

    public static let get: Self = "GET"
    public static let post: Self = "POST"
    public static let put: Self = "PUT"
    public static let patch: Self = "PATCH"
    public static let delete: Self = "DELETE"

    public init(_ name: String) {
        self.name = name
    }

    public let name: String
}

extension HTTPMethod: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
