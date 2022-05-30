import Foundation
import URLRouting

extension URLRoutingClient {
    public static func connection<R: ParserPrinter>(
        router: R,
        session: URLSession = .shared,
        decoder: JSONDecoder = .init()
    ) -> Self
    where R.Input == URLRequestData, R.Output == Route {
        Self.init(
            request: { route in
                let throttle = router.throttleOption(for: route)

            },
            decoder: decoder
        )
    }
}
