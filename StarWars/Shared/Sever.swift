import Foundation
import HTTP
import os

let logger = Logger(subsystem: "works.dan.StarWars", category: "Networking")

/// Define a server environment
extension Environment.Server {
    public static let starWars: Self = .init(
        host: "swapi.dev",
        pathPrefix: "/api"
    )
}

/// Create a connection
let connection = Connection(StarWarsAPI.router) {
    NetworkTransport
        .live()
        .throttle(maximumNumberOfRequests: 3)
        .cached()
//        .retry(strategy: ConstantBackoff(delay: 1.0, maximumNumberOfAttempts: 3))
        .log(using: logger)
        .resetGuard()
}
