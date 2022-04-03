
import Foundation

/// An HTTP Loader which runs a series of other loaders in turn.
///
/// A general entry point into ``HTTPLoaderBuilder`` syntax, which
/// can be used to build custom HTTP loading pipelines.
public struct Connection<Loader: HTTPLoadable> {

    public let loader: Loader

    @inlinable
    public init(@HTTPLoaderBuilder _ build: () -> Loader) {
        loader = build()
    }
}

public extension Connection {

    func send(_ request: HTTPRequest) -> Task<HTTPResponse, Error> {
        Task<HTTPResponse, Error> {
            // TODO: Add Reset Guard Logic here.
            // TODO: Add Cancel on Reset logic to Connection

            /// Throw an error if the task was already cancelled.
            try Task.checkCancellation()

            return try await loader.load(request)
        }
    }

    func request<Body>(_ request: Request<Body>) -> Task<Response<Body>, Error> {
        Task {
            let value = try await send(request.http).value
            return try await request.decode(value)
        }
    }
}
