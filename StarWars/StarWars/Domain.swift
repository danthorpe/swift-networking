import Foundation
import Networking
import os.log
import Tagged

/// Define domain types
enum Category: Int, Hashable, CaseIterable, Identifiable, Codable {
    case people
    case planets
    case films
    case species
    case vehicles
    case starships

    var id: Int { rawValue }

    var localizedName: String {
        switch self {
        case .people:
            return "People"
        case .planets:
            return "Planets"
        case .films:
            return "Films"
        case .species:
            return "Species"
        case .vehicles:
            return "Vehicles"
        case .starships:
            return "Starships"
        }
    }
}

struct Person: Equatable, Codable, Hashable, Identifiable {
    let name: String
    let height: String
    let mass: String
    let hairColor: String
    let skinColor: String
    let eyeColor: String
    let birthYear: String
    let gender: String
    let homeworld: URL?
    let films: [URL]
    let species: [URL]
    let vehicles: [URL]
    let starships: [URL]
    let created: Date
    let edited: Date
    let url: URL

    typealias ID = Tagged<Person, Int>
    var id: ID { ID(rawValue: Int(url.lastPathComponent)!) }
}

struct Planet: Equatable, Codable, Hashable, Identifiable {
    let name: String
    let url: URL

    typealias ID = Tagged<Planet, Int>
    var id: ID { ID(rawValue: Int(url.lastPathComponent)!) }
}

struct Film: Equatable, Codable, Hashable, Identifiable {
    let url: URL

    typealias ID = Tagged<Film, Int>
    var id: ID { ID(rawValue: Int(url.lastPathComponent)!) }
}

struct Species: Equatable, Codable, Hashable, Identifiable {
    let url: URL

    typealias ID = Tagged<Species, Int>
    var id: ID { ID(rawValue: Int(url.lastPathComponent)!) }
}

struct Vehicle: Equatable, Codable, Hashable, Identifiable {
    let url: URL

    typealias ID = Tagged<Vehicle, Int>
    var id: ID { ID(rawValue: Int(url.lastPathComponent)!) }
}

struct Starship: Equatable, Codable, Hashable, Identifiable {
    let url: URL

    typealias ID = Tagged<Starship, Int>
    var id: ID { ID(rawValue: Int(url.lastPathComponent)!) }
}


enum StarWarsAPI {

    struct ListResult<Element: Decodable>: Decodable {
        let count: Int
        let next: URL?
        let previous: URL?
        let results: [Element]
    }

    struct Home: Decodable {
        let people: URL?
        let planets: URL?
        let films: URL?
        let species: URL?
        let vehicles: URL?
        let starships: URL?
    }

    struct Person: Equatable, Decodable, Hashable {
        let name: String
        let height: String
        let mass: String
        let hairColor: String
        let skinColor: String
        let eyeColor: String
        let birthYear: String
        let gender: String
        let homeworld: URL
        let films: [URL]
        let species: [URL]
        let vehicles: [URL]
        let starships: [URL]
        let created: Date
        let edited: Date
        let url: URL
    }
}


@MainActor
final class DataRepository: ObservableObject {
    let connection: Connection<AppRoute>

    @Published var people: [Person] = []
    @Published var planets: [Planet] = []

    init(_ networkStack: some NetworkStackable) {
        self.connection = Connection(
            router: router,
            decoder: Server.decoder,
            with: networkStack
        )
    }

    func fetch(category: Category, page: UInt? = nil) async throws {
        switch (category, page) {
        case (.people, .none), (.people, .some(0)), (.people, .some(1)):
            try await fetch(PeopleRoute.home)
        case let (.people, .some(page)):
            try await fetch(PeopleRoute.page(number: Int(page)))
        case (.planets, .none), (.planets, .some(0)), (.planets, .some(1)):
            try await fetch(PlanetsRoute.home)
        case let (.planets, .some(page)):
            try await fetch(PlanetsRoute.page(number: Int(page)))

        default:
            break
        }
    }

    func fetch(_ route: PeopleRoute) async throws {
        switch route {
        case .home, .page:
            let list = try await connection.value(for: .people(route), as: StarWarsAPI.ListResult<Person>.self).body
            people.append(contentsOf: list.results)
        case .id:
            break
        }
    }

    func fetch(_ route: PlanetsRoute) async throws {
        switch route {
        case .home, .page:
            let list = try await connection.value(for: .planets(route), as: StarWarsAPI.ListResult<Planet>.self).body
            planets.append(contentsOf: list.results)
        case .id:
            break
        }
    }
}

extension DataRepository {
    static let live = DataRepository(Server.live)
}
