import Foundation

extension NetworkingComponent {

  public var authority: String {
    resolve(HTTPRequestData()).authority
  }
}
