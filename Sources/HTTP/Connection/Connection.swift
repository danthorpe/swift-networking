
import Foundation

/// An HTTP Loader which runs a series of other loaders in turn.
///
/// A general entry point into ``HTTPLoaderBuilder`` syntax, which
/// can be used to build custom HTTP loading pipelines.
public struct Connection<Upstream: HTTPLoadable> {

    public let upstream: Upstream

    public init<Loader>(
        @HTTPLoaderBuilder _ build: () -> Loader
    )
    where Loader: HTTPLoadable, Upstream == GenerateRequestIdentifiers<Loader>
    {
        upstream = GenerateRequestIdentifiers(upstream: build())
    }
}

public extension Connection {

    func send(_ request: HTTPRequest) -> Task<HTTPResponse, Error> {
        Task<HTTPResponse, Error> {
            // TODO: Add Reset Guard Logic here.
            // TODO: Add Cancel on Reset logic to Connection

            /// Throw an error if the task was already cancelled.
            try Task.checkCancellation()

            return try await upstream.load(request)
        }
    }

    func request<Body>(
        _ request: Request<Body>
    ) -> Task<Response<Body>, Error> {
        Task {
            let value = try await send(request.http).value
            return try request.decode(value)
        }
    }

    func send<Body, Requests>(
        _ requests: Requests
    ) async throws -> [Response<Body>]
    where Requests: Collection, Requests.Element == Request<Body>
    {
        var responses: [Response<Body>] = []
        responses.reserveCapacity(requests.count)
        
        try await withThrowingTaskGroup(of: Response<Body>.self) { group in
            for element in requests {
                group.addTask {
                    try await self.request(element).value
                }
            }

            for try await element in group {
                responses.append(element)
            }
        }

        return responses
    }
}
