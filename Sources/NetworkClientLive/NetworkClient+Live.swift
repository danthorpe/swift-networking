import Dependencies
import Foundation
import NetworkClient
import Networking

extension NetworkClient: DependencyKey {
  public static let liveValue: Self = {
    let stack = URLSession.shared
      .throttled(max: 3)
      .automaticRetry()
      .duplicatesRemoved()
    return NetworkClient { stack }
  }()
}
