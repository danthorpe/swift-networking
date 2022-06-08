import EnvironmentProviders
import Foundation
import Cache
import Networking
import os
import URLRouting

enum Server {
    static let logger = Logger(subsystem: "works.dan.StarWars", category: "Networking")

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let fmtr = DateFormatter()
        fmtr.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        decoder.dateDecodingStrategy = .formatted(fmtr)
        return decoder
    }()

    static let live = NetworkStack
        .use(session: .shared)
        .throttle(max: 3)
        .retry()
        .cached(fileName: "StarWars")
        .removeDuplicates()
        .use(logger: logger)
}

//
//let connection = Connection(
//    router: router,
//    decoder: decoder,
//    with: NetworkStack
//        .use(session: .shared)
//        .throttle(max: 3)
//        .retry()
//        .cached(fileName: "StarWars")
//        .removeDuplicates()
//        .use(logger: logger)
//)
