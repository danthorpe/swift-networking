import Foundation
import os.log

extension NetworkingComponent {
  /// Set the hostname of the server.
  /// - Parameter authority: the hostname of your server, e.g. apple.com
  /// - Returns: some ``NetworkingComponent``
  public func server(authority: String) -> some NetworkingComponent {
    server(mutate: \.authority) { _ in
      authority
    } log: { logger, request in
      logger?.debug("💁 authority -> '\(authority)' \(request.debugDescription)")
    }
  }
}
