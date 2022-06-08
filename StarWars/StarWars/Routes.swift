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
    Route(.case(PeopleRoute.home))
    Route(.case(PeopleRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(PeopleRoute.id)) {
        Path { Digits() }
    }
}

enum PlanetsRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let planetsRoute = OneOf {
    Route(.case(PlanetsRoute.home))
    Route(.case(PlanetsRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(PlanetsRoute.id)) {
        Path { Digits() }
    }
}

enum FilmsRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let filmsRoute = OneOf {
    Route(.case(FilmsRoute.home))
    Route(.case(FilmsRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(FilmsRoute.id)) {
        Path { Digits() }
    }
}

enum SpeciesRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let speciesRoute = OneOf {
    Route(.case(SpeciesRoute.home))
    Route(.case(SpeciesRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(SpeciesRoute.id)) {
        Path { Digits() }
    }
}

enum VehiclesRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let vehiclesRoute = OneOf {
    Route(.case(VehiclesRoute.home))
    Route(.case(VehiclesRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(VehiclesRoute.id)) {
        Path { Digits() }
    }
}

enum StarshipsRoute: Equatable {
    case home
    case page(number: Int)
    case id(Int)
}

let starshipsRoute = OneOf {
    Route(.case(StarshipsRoute.home))
    Route(.case(StarshipsRoute.page(number:))) {
        Query {
            Field("page", default: 1) { Digits() }
        }
    }
    Route(.case(StarshipsRoute.id)) {
        Path { Digits() }
    }
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
    Route(.case(AppRoute.categories))
    Route(.case(AppRoute.people)) {
        Path { "people" }
        peopleRoute
    }
    Route(.case(AppRoute.planets)) {
        Path { "planets" }
        planetsRoute
    }
    Route(.case(AppRoute.films)) {
        Path { "films" }
        filmsRoute
    }
    Route(.case(AppRoute.species)) {
        Path { "species" }
        speciesRoute
    }
    Route(.case(AppRoute.vehicles)) {
        Path { "vehicles" }
        vehiclesRoute
    }
    Route(.case(AppRoute.starships)) {
        Path { "starships" }
        starshipsRoute
    }
}
.baseURL("https://swapi.dev/api")
