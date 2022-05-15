import Foundation
import URLRouting

extension StarWars {
    enum PeopleRoute: Equatable {
        case home
    }
    enum PlanetsRoute: Equatable {
        case home
    }
    enum FilmsRoute: Equatable {
        case home
    }
    enum APIRoute: Equatable {
        case people(PeopleRoute)
        case planets(PlanetsRoute)
        case films(FilmsRoute)
    }
    enum AppRoute: Equatable {
        case home
        case api(APIRoute)
    }

}


extension StarWars {
    static let apiRouter = OneOf {
        // GET /api/people
        Route(.case(StarWars.APIRoute.people(.home))) {
            Path { "people" }
        }
        // GET /api/planets
        Route(.case(StarWars.APIRoute.planets(.home))) {
            Path { "planets" }
        }
        // GET /api/films
        Route(.case(StarWars.APIRoute.films(.home))) {
            Path { "films" }
        }
    }

    static let router = OneOf {
        // GET /api
        Route(.case(StarWars.AppRoute.home))
        Route(.case(StarWars.AppRoute.api)) {
            Path { "api" }
            apiRouter
        }
    }.baseURL("https://swapi.dev/api")
}
