import Foundation
import os.log

extension NetworkingComponent {
  /// Set the path of each request
  ///
  /// - Note: This will replace the path configured on each ``HTTPRequestData``,
  /// so it's utility if for when you only have a single endpoint to request.
  ///
  /// - Parameter newPath: a new `String` to replace the path
  /// - Returns: some ``NetworkingComponent``
  public func server(path newPath: String) -> some NetworkingComponent {
    server(mutate: \.path) { _ in
      newPath
    } log: { logger, request in
      logger?.debug("💁 path -> '\(newPath)' \(request.debugDescription)")
    }
  }

  /// Set a path prefix for each request. This is pretty handy for when all requests
  /// start with the same path prefix.
  /// - Parameters:
  ///   - prefixPath: a `String` to use as a prefix before
  ///   the path which is already configured on the request.
  ///   - delimiter: the path delimiter, defaults to "/"
  /// - Returns: some ``NetworkingComponent``
  public func server(prefixPath: String, delimiter: String = "/") -> some NetworkingComponent {
    server(mutate: \.path) { path in
      if path.hasPrefix(delimiter + prefixPath) {
        return path
      }
      return delimiter + prefixPath + path
    } log: { logger, request in
      logger?.debug("💁 prefix path -> '\(prefixPath)' \(request.debugDescription)")
    }
  }

  /// Set the character set to use for query items in the request
  /// - Parameter allowedCharacters: `CharacterSet` for the characters allowed in query parameters
  /// - Returns: some ``NetworkingComponent``
  public func server(queryItemsAllowedCharacters allowedCharacters: CharacterSet) -> some NetworkingComponent {
    server(mutate: \.queryItemsAllowedCharacters) { _ in
      allowedCharacters
    } log: { logger, request in
      if let logger, let queryItems = request.queryItems {
        logger.debug("💁 queryItems -> '\(queryItems)' \(request.debugDescription)")
      }
    }
  }
}
