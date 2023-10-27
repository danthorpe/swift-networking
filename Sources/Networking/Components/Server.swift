import HTTPTypes
import os.log

extension NetworkingComponent {

  public func server(scheme: String) -> some NetworkingComponent {
    server(mutate: \.scheme) { _ in
      scheme
    } log: { logger, request in
      logger?.debug("💁 scheme -> '\(scheme)' \(request.debugDescription)")
    }
  }

  public func server(authority: String) -> some NetworkingComponent {
    server(mutate: \.authority) { _ in
      authority
    } log: { logger, request in
      logger?.debug("💁 authority -> '\(authority)' \(request.debugDescription)")
    }
  }

  public func server(headerField name: HTTPField.Name, _ value: String) -> some NetworkingComponent {
    server(mutate: \.headerFields) { headers in
      var copy = headers
      copy[name] = value
      return copy
    } log: { logger, request in
      guard let logger else { return }
      guard name.requiresPrivateLogging else {
        logger.debug(
          "💁 header \(name) -> '\(value, privacy: .public)' \(request.debugDescription)"
        )
        return
      }
      if name.requireHashPrivateLogging {
        logger.debug(
          "💁 header \(name) -> '\(value, privacy: .private(mask: .hash))' \(request.debugDescription)"
        )
      } else {
        logger.debug(
          "💁 header \(name) -> '\(value, privacy: .private)' \(request.debugDescription)"
        )
      }
    }
  }

  public func server(customHeaderField name: String, _ value: String) -> some NetworkingComponent {
    server(mutate: \.headerFields) { headerFields in
      guard let fieldName = HTTPField.Name(name) else {
        assertionFailure("Custom Header \(name) is not a valid HTTPField Name")
        return headerFields
      }
      var copy = headerFields
      copy[fieldName] = value
      return copy
    } log: { logger, request in
      guard nil != HTTPField.Name(name) else { return }
      logger?.debug(
        "💁 header \(name) -> '\(value, privacy: .private)' \(request.debugDescription)"
      )
    }
  }

  public func server(path newPath: String) -> some NetworkingComponent {
    server(mutate: \.path) { _ in
      newPath
    } log: { logger, request in
      logger?.info("💁 path -> '\(newPath)' \(request.debugDescription)")
    }
  }

  public func server(prefixPath: String, delimiter: String = "/") -> some NetworkingComponent {
    server(mutate: \.path) { path in
      delimiter + prefixPath + path
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
  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<
    HTTPResponseData
  > {
    var copy = request
    mutate(&copy)
    return upstream.send(copy)
  }
}
