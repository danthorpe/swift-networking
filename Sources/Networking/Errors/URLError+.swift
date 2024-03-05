import Foundation

extension URLError {

  var isNotConnectedToInternet: Bool {
    switch code {
    case .cannotFindHost,
        .cannotConnectToHost,
        .networkConnectionLost,
        .notConnectedToInternet:
      return true
    default:
      return false
    }
  }
}
