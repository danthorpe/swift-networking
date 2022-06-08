import XCTest
@testable import StarWars

final class RouterTests: XCTestCase {

    func test__paths() {
        XCTAssertEqual(router.path(for: .categories), "/api")
        XCTAssertEqual(router.path(for: .people(.home)), "/api/people")
        XCTAssertEqual(router.path(for: .people(.id(1))), "/api/people/1")
        XCTAssertEqual(router.path(for: .people(.id(2))), "/api/people/2")
        XCTAssertEqual(router.path(for: .planets(.home)), "/api/planets")
        XCTAssertEqual(router.path(for: .planets(.id(1))), "/api/planets/1")
        XCTAssertEqual(router.path(for: .planets(.id(2))), "/api/planets/2")
        XCTAssertEqual(router.path(for: .films(.home)), "/api/films")
        XCTAssertEqual(router.path(for: .films(.id(1))), "/api/films/1")
        XCTAssertEqual(router.path(for: .films(.id(2))), "/api/films/2")
        XCTAssertEqual(router.path(for: .species(.home)), "/api/species")
        XCTAssertEqual(router.path(for: .species(.id(1))), "/api/species/1")
        XCTAssertEqual(router.path(for: .species(.id(2))), "/api/species/2")
        XCTAssertEqual(router.path(for: .vehicles(.home)), "/api/vehicles")
        XCTAssertEqual(router.path(for: .vehicles(.id(1))), "/api/vehicles/1")
        XCTAssertEqual(router.path(for: .vehicles(.id(2))), "/api/vehicles/2")
        XCTAssertEqual(router.path(for: .starships(.home)), "/api/starships")
        XCTAssertEqual(router.path(for: .starships(.id(1))), "/api/starships/1")
        XCTAssertEqual(router.path(for: .starships(.id(2))), "/api/starships/2")
    }
}
