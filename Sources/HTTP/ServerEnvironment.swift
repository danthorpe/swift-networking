//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public struct ServerEnvironment {

    public var host: String
    public var pathPrefix: String
    public var headers: [String: String]
    public var query: [URLQueryItem]

    public init(host: String, pathPrefix: String = "", headers: [String: String] = [:], query: [URLQueryItem] = []) {
        // make sure the pathPrefix starts with a /
        let prefix = pathPrefix.hasPrefix("/") ? "" : "/"
        self.host = host
        self.pathPrefix = prefix + pathPrefix
        self.headers = headers
        self.query = query
    }
}

// MARK: - Request Option

extension ServerEnvironment: HTTPRequestOption {

    public static let defaultValue: ServerEnvironment? = nil
}

public extension HTTPRequest {

    var server: ServerEnvironment? {
        get { self[option: ServerEnvironment.self] }
        set { self[option: ServerEnvironment.self] = newValue }
    }
}
