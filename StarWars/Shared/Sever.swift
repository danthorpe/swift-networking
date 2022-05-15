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
let connection = Connection {
    TransportLoader(URLSession.shared)
        .throttle(maximumNumberOfRequests: 3)
        .apply(environment: .starWars)
        .log(using: logger)
        .resetGuard()
}

