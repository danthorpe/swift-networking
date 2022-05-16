import Foundation
import URLRouting

extension StarWarsAPI {
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
        case home
        case people(PeopleRoute = .home)
        case planets(PlanetsRoute = .home)
        case films(FilmsRoute = .home)
    }
    enum AppRoute: Equatable {
        case api(APIRoute = .home)
    }

}


extension StarWarsAPI {
    static let apiRouter = OneOf {
        // GET /api/people
        Route(.case(StarWarsAPI.APIRoute.people(.home))) {
            Path { "people" }
        }
        // GET /api/planets
        Route(.case(StarWarsAPI.APIRoute.planets(.home))) {
            Path { "planets" }
        }
        // GET /api/films
        Route(.case(StarWarsAPI.APIRoute.films(.home))) {
            Path { "films" }
        }
    }

    static let router = OneOf {
        // GET /api
        Route(.case(StarWarsAPI.AppRoute.api(.home)))
        Route(.case(StarWarsAPI.AppRoute.api)) {
            apiRouter
        }
    }.baseURL("https://swapi.dev/api")
}
