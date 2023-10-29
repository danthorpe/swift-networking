import Foundation
import os.log

extension NetworkingComponent {
  public func server(path newPath: String) -> some NetworkingComponent {
    server(mutate: \.path) { _ in
      newPath
    } log: { logger, request in
      logger?.debug("💁 path -> '\(newPath)' \(request.debugDescription)")
    }
  }

  public func server(prefixPath: String, delimiter: String = "/") -> some NetworkingComponent {
    server(mutate: \.path) { path in
      delimiter + prefixPath + path
    } log: { logger, request in
      logger?.debug("💁 prefix path -> '\(prefixPath)' \(request.debugDescription)")
    }
  }

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
