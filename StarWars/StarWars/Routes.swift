import Foundation
import Networking
import Tagged
import URLRouting

enum PeopleRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let peopleRoute = OneOf {
    Route(.case(PeopleRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(PeopleRoute.id)) {
        Path { Digits() }
    }
    Route(.case(PeopleRoute.home))
}

enum PlanetsRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let planetsRoute = OneOf {
    Route(.case(PlanetsRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(PlanetsRoute.id)) {
        Path { Digits() }
    }
    Route(.case(PlanetsRoute.home))
}

enum FilmsRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let filmsRoute = OneOf {
    Route(.case(FilmsRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(FilmsRoute.id)) {
        Path { Digits() }
    }
    Route(.case(FilmsRoute.home))
}

enum SpeciesRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let speciesRoute = OneOf {
    Route(.case(SpeciesRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(SpeciesRoute.id)) {
        Path { Digits() }
    }
    Route(.case(SpeciesRoute.home))
}

enum VehiclesRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let vehiclesRoute = OneOf {
    Route(.case(VehiclesRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(VehiclesRoute.id)) {
        Path { Digits() }
    }
    Route(.case(VehiclesRoute.home))
}

enum StarshipsRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let starshipsRoute = OneOf {
    Route(.case(StarshipsRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(StarshipsRoute.id)) {
        Path { Digits() }
    }
    Route(.case(StarshipsRoute.home))
}

enum AppRoute: Equatable {
    case categories
    case people(PeopleRoute = .home)
    case planets(PlanetsRoute = .home)
    case films(FilmsRoute = .home)
    case species(SpeciesRoute = .home)
    case vehicles(VehiclesRoute = .home)
    case starships(StarshipsRoute = .home)
}

let router = OneOf {
    Route(.case(AppRoute.categories)) {
        Path { "api" }
    }
    Route(.case(AppRoute.people)) {
        Path { "api"; "people" }
        peopleRoute
    }
    Route(.case(AppRoute.planets)) {
        Path { "api"; "planets" }
        planetsRoute
    }
    Route(.case(AppRoute.films)) {
        Path { "api"; "films" }
        filmsRoute
    }
    Route(.case(AppRoute.species)) {
        Path { "api"; "species" }
        speciesRoute
    }
    Route(.case(AppRoute.vehicles)) {
        Path { "api"; "vehicles" }
        vehiclesRoute
    }
    Route(.case(AppRoute.starships)) {
        Path { "api"; "starships" }
        starshipsRoute
    }
}
.baseURL("https://swapi.dev/")
