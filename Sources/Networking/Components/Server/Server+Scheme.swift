import Foundation
import os.log

extension NetworkingComponent {

  public func server(scheme: String) -> some NetworkingComponent {
    server(mutate: \.scheme) { _ in
      scheme
    } log: { logger, request in
      logger?.debug("💁 scheme -> '\(scheme)' \(request.debugDescription)")
    }
  }
}
