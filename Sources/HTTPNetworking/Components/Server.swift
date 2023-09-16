import HTTPTypes
import os.log

extension NetworkingComponent {

    public func server(authority: String?) -> some NetworkingComponent {
        server(mutate: \.authority) { _ in
            authority
        } log: { logger, request in
            logger?.info("💁 authority -> '\(authority ?? "no value")' \(request.debugDescription)")
        }
    }

    public func server(headerField name: HTTPField.Name, value: String?) -> some NetworkingComponent {
        server(mutate: \.headerFields) { headers in
            var copy = headers
            copy[name] = value
            return copy
        } log: { logger, request in
            logger?.info("💁 header \(name) -> '\(value ?? "no value")' \(request.debugDescription)")
        }
    }

    public func server(prefixPath: String, delimiter: String = "/") -> some NetworkingComponent {
        server(mutate: \.path) { path in
            guard let path else { return prefixPath }
            return prefixPath + delimiter + path
        } log: { logger, request in
            logger?.info("💁 prefix path -> '\(prefixPath)' \(request.debugDescription)")
        }
    }

    public func server<Value>(
        mutate keypath: WritableKeyPath<HTTPRequestData, Value>,
        with transform: @escaping (Value) -> Value,
        log: @escaping (Logger?, HTTPRequestData) -> Void
    ) -> some NetworkingComponent {
        server { request in
            @NetworkEnvironment(\.logger) var logger
            request[keyPath: keypath] = transform(request[keyPath: keypath])
            log(logger, request)
        }
    }

    public func server(
        _ mutateRequest: @escaping (inout HTTPRequestData) -> Void
    ) -> some NetworkingComponent {
        modified(MutateRequest(mutate: mutateRequest))
    }
}

private struct MutateRequest: NetworkingModifier {
    let mutate: (inout HTTPRequestData) -> Void
    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        var copy = request
        mutate(&copy)
        return upstream.send(copy)
    }
}
