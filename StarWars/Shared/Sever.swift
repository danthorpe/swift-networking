import Foundation
import Cache
import Networking
import os
import URLRouting

let logger = Logger(subsystem: "works.dan.StarWars", category: "Networking")

let live = NetworkStack
    .use(session: .shared)
    .throttle(max: 3)
    .use(cache: .init(size: 100))
    .removeDuplicates()
    .use(logger: logger)

let connection = Connection.use(router: StarWarsAPI.router, with: live)
