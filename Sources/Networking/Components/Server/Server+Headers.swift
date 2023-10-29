import Foundation
import HTTPTypes
import os.log

extension NetworkingComponent {
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

  @NetworkingComponentBuilder
  public func server(customHeaderField name: String, _ value: String) -> some NetworkingComponent {
    if let fieldName = HTTPField.Name(name) {
      server(mutate: \.headerFields) { headerFields in
        var copy = headerFields
        copy[fieldName] = value
        return copy
      } log: { logger, request in
        logger?.debug(
          "💁 header \(name) -> '\(value, privacy: .private)' \(request.debugDescription)"
        )
      }
    } else {
      self
    }
  }
}
