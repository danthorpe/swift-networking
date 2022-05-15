import Foundation
import Tagged

/// Define domain types

public enum StarWars { }

extension StarWars {
    public struct Home: Decodable {
        public let people: URL?
        public let planets: URL?
        public let films: URL?
        public let species: URL?
        public let vehicles: URL?
        public let starships: URL?
    }
    public struct People: Decodable {
        public let count: Int
        public let next: URL?
        public let previous: URL?
        public let results: [Person]
    }

    public struct Person: Equatable, Decodable {
        public typealias ID = Tagged<Person, Int>
        public let name: String
        public let height: Int
        public let mass: Int
        public let hairColor: String
        public let skinColor: String
        public let eyeColor: String
        public let birthYear: String
        public let gender: String
        public let homeworld: URL?
        public let films: [URL]
        public let species: [URL]
        public let vehicles: [URL]
        public let starships: [URL]
        public let created: Date
        public let edited: Date
        public let url: URL?
    }
}
