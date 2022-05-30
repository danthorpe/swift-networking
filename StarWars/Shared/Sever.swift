import Foundation
import Networking
import os

let logger = Logger(subsystem: "works.dan.StarWars", category: "Networking")

/// Define a server environment
extension Environment.Server {
    public static let starWars: Self = .init(
        host: "swapi.dev",
        pathPrefix: "/api"
    )
}

/*

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
*/

let live = NetworkStack
    .use(session: .shared)
    .use(cache: ())
    .use(logger)

let connection = Connection.use(router: StarWarsAPI.router, with: live)
