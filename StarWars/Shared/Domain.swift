import Foundation
import Tagged

/// Define domain types

enum StarWarsAPI {
    struct Home: Decodable {
        let people: URL?
        let planets: URL?
        let films: URL?
        let species: URL?
        let vehicles: URL?
        let starships: URL?
    }

    struct People: Decodable {
        let count: Int
        let next: URL?
        let previous: URL?
        let results: [Person]
    }

    struct Person: Equatable, Decodable, Hashable {
        typealias ID = Tagged<Person, Int>
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
        let url: URL?
    }
}
