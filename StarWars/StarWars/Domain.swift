import Combine
import Foundation
import Networking
import OrderedCollections
import os.log
import URLRouting
import Tagged

protocol StarWarsResource: Hashable, Identifiable, Comparable {
    static var localizedTypeName: String { get }

    var name: String { get }
    var url: URL { get }
}

extension StarWarsResource {
    static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.url.absoluteString < rhs.url.absoluteString
    }
}

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

struct Person: Equatable, Codable, Hashable, Identifiable, StarWarsResource {
    static var localizedTypeName: String { "People" }

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

struct Planet: Equatable, Codable, Hashable, Identifiable, StarWarsResource {
    static var localizedTypeName: String { "Planets" }
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

struct ListResult<Element> {
    let count: Int
    let next: URL?
    let previous: URL?
    let results: [Element]
}

extension ListResult: Decodable where Element: Decodable { }

extension ListResult where Element: StarWarsResource {

    var nextPageRoute: AppRoute? {
        guard let url = next else {
            return nil
        }
        guard let data = URLRequestData(url: url) else {
            return nil
        }
        let route = try? router.parse(data)
        return route
    }
}

enum StarWarsAPI {

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

struct ResourceDataStore<Resource: StarWarsResource> {
    typealias PageNumber = Int
    private(set) var data: CurrentValueSubject<OrderedDictionary<PageNumber, ListResult<Resource>>, Never> = .init([:])

    var lastPageNumber: PageNumber {
        data.value.keys.sorted().last ?? 1
    }

    func list(for pageNumber: PageNumber) -> ListResult<Resource>? {
        data.value[pageNumber]
    }

    func index(of resource: Resource) -> (index: Int, page: PageNumber, list: ListResult<Resource>)? {
        for (page, list) in data.value {
            if let index = list.results.firstIndex(of: resource) {
                return (page, index, list)
            }
        }
        return nil
    }

    func shouldFetchAnotherPage(of resource: Resource) -> AppRoute? {
        // Get the index for the resource
        guard let (page, index, list) = index(of: resource) else { return nil }
        // Check that there is another list to get
        guard let route = list.nextPageRoute else { return nil }
        // Check that this is the last page we've already fetched
        guard page == lastPageNumber else { return nil }
        // Only return true if the item is the last in the list results
        guard index == list.results.endIndex - 1 else { return nil }
        // Return the next list page number
        return route
    }

    mutating func append(_ list: ListResult<Resource>, for page: PageNumber) {
        data.send(data.value.merging([page: list], uniquingKeysWith: { $1 }))
    }
}

@MainActor
final class DataRepository: ObservableObject {
    let connection: Connection<AppRoute>

    private var peopleData = ResourceDataStore<Person>()
    private var planetsData = ResourceDataStore<Planet>()

    @Published var people: [Person] = []
    @Published var planets: [Planet] = []

    init<Stack: NetworkStackable>(_ networkStack: Stack) {
        self.connection = Connection(
            router: router,
            decoder: Server.decoder,
            with: networkStack
        )

        peopleData.data
            .map { $0.values.flatMap(\.results) }
            .assign(to: &$people)

        planetsData.data
            .map { $0.values.flatMap(\.results) }
            .assign(to: &$planets)
    }

    func fetch<Resource: StarWarsResource>(_ route: AppRoute, as resource: Resource.Type) async throws {
        switch (resource, route) {

        case (is Person.Type, .people(.home)):
            try await fetch(.people(.page(number: 1)), as: Person.self)

        case let (is Person.Type, .people(.page(number: pageNumber))):
            let list = try await connection.value(for: route, as: ListResult<Person>.self).body
            peopleData.append(list, for: pageNumber)

        case (is Planet.Type, .planets(.home)):
            try await fetch(.planets(.page(number: 1)), as: Planet.self)

        case let (is Planet.Type, .planets(.page(number: pageNumber))):
            let list = try await connection.value(for: route, as: ListResult<Planet>.self).body
            planetsData.append(list, for: pageNumber)

        default:
            break
        }
    }

    func fetch<Resource: StarWarsResource>(resource: Resource.Type, page: UInt = 1) async throws {
        switch resource {
        case is Person.Type:
            try await fetch(.people(.page(number: Int(page))), as: Person.self)
        case is Planet.Type:
            try await fetch(.planets(.page(number: Int(page))), as: Planet.self)
        default:
            break
        }
    }

    func fetchMore<Resource: StarWarsResource>(of resource: Resource) async throws {
        switch type(of: resource) {
        case is Person.Type:
            if let person = resource as? Person, let route = peopleData.shouldFetchAnotherPage(of: person) {
                try await fetch(route, as: Person.self)
            }
        case is Planet.Type:
            if let planet = resource as? Planet, let route = planetsData.shouldFetchAnotherPage(of: planet) {
                try await fetch(route, as: Planet.self)
            }
        default:
            break
        }
    }
}

extension DataRepository {
    static let live = DataRepository(Server.live)
}
