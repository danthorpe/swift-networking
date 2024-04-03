import Foundation
import os.log

extension NetworkingComponent {

  /// Set the HTTP scheme to use.
  ///
  /// The default scheme used in ``HTTPRequestData`` values are already "https".
  ///
  /// - Parameter scheme: the scheme `String`
  /// - Returns: some ``NetworkingComponent``
  public func server(scheme: String) -> some NetworkingComponent {
    server(mutate: \.scheme) { _ in
      scheme
    } log: { logger, request in
      logger?.debug("💁 scheme -> '\(scheme)' \(request.debugDescription)")
    }
  }
}
