import Foundation

extension HTTPRequestData {
  func applyAuthenticationCredentials() -> HTTPRequestData {
    if authenticationMethod == .basic, let basicCredentials {
      return basicCredentials.apply(to: self)
    } else if authenticationMethod == .bearer, let bearerCredentials {
      return bearerCredentials.apply(to: self)
    }
    return self
  }
}
