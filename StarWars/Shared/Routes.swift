import Foundation
import URLRouting

extension StarWars {
    enum PeopleRoute {
        case home
    }
    enum PlanetsRoute {
        case home
    }
    enum AppRoute {
        case home
        case people(PeopleRoute)
        case planets(PlanetsRoute)
    }
}


extension StarWars {
    static let router = OneOf {
        // GET /api
        Route(.case(StarWars.AppRoute.home)) {
            Path { "api" }
        }
        // GET /api/people
        Route(.case(StarWars.AppRoute.people(.home))) {
            Path { "api"; "people" }
        }
        // GET /api/planets
        Route(.case(StarWars.AppRoute.planets(.home))) {
            Path { "api"; "planets" }
        }
    }
}
