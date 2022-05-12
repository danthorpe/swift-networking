import _Concurrency
import Foundation
import HTTP
import Tagged
import PlaygroundSupport
import os

PlaygroundPage.current.needsIndefiniteExecution = true

public enum StarWars { }

/// Define a server environment
extension Environment.Server {
    public static let starWars = Self(
        host: "swapi.dev",
        pathPrefix: "/api"
    )
}

let logger = Logger(subsystem: "works.dan.StarWars", category: "Networking")

/// Create a connection
let connection = Connection {
    TransportLoader(URLSession.shared)
        .throttle(maximumNumberOfRequests: 3)
        .apply(environment: .starWars)
        .log(using: logger)
        .resetGuard()
}

/// Define a domain type
extension StarWars {
    public struct Person: Equatable, Decodable {
        public typealias ID = Tagged<Person, Int>
        public let name: String
    }
}

/// Add static functions to create request value for a specific domain type
extension Request where Body == StarWars.Person {
    public static func person(_ id: StarWars.Person.ID) -> Request<StarWars.Person> {
        var request = HTTPRequest()
        request.path = "people/\(id)"
        return Request(json: request)
    }
}

func fetchManyPeople(ids: [Int] = Array(1...16)) async throws -> [StarWars.Person] {
    let requests = ids
        .map(StarWars.Person.ID.init(rawValue:))
        .map(Request.person)

    let responses = try await connection.send(requests)

    return responses.map { $0.body }
}

Task.detached {
    do {
        let people = try await fetchManyPeople()
        print(people.map(\.name))
    }
    catch {
        print("Error: \(error)")
    }
    PlaygroundPage.current.finishExecution()
}
