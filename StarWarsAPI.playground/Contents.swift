import _Concurrency
import Foundation
import HTTP
import Tagged
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

public enum StarWars { }

/// Define a server environment
extension Environment.Server {
    public static let starWars = Self(
        host: "swapi.dev",
        pathPrefix: "/api"
    )
}

/// Create a connection
let connection = Connection {
    TransportLoader(URLSession.shared)
        .log(using: .init(subsystem: "works.dan.StarWars", category: "Networking"))
        .throttle(maximumNumberOfRequests: 3)
        .apply(environment: .starWars)
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

/// Get a task for this request, which allows it to be cancelled.
let task = connection.request(.person(1))

Task.detached {

    /// Await the task's value to access it's body property
    do {
        let person = try await task.value.body
        print("Success: \(person)")
    }
    catch {
        print("Failure: \(error)")
    }

    PlaygroundPage.current.finishExecution()
}



