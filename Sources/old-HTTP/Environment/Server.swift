//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

extension Environment {
    public struct Server {

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
}

/// Task Local property
public extension Environment {

    @TaskLocal
    static var server: Server?
}


// MARK: - Request Option

/// A Request Option denoting the default server on each request
extension Environment.Server: HTTPRequestOption {

    public static let defaultValue: Environment.Server? = Environment.server
}

public extension HTTPRequest {

    var server: Environment.Server? {
        get { self[option: Environment.Server.self] }
        set { self[option: Environment.Server.self] = newValue }
    }
}
