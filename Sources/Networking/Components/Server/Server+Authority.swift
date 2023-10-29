import Foundation
import os.log

extension NetworkingComponent {
  public func server(authority: String) -> some NetworkingComponent {
    server(mutate: \.authority) { _ in
      authority
    } log: { logger, request in
      logger?.debug("💁 authority -> '\(authority)' \(request.debugDescription)")
    }
  }
}
