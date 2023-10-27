import Foundation

extension URL {

  public init(static staticString: StaticString) {
    guard let url = URL(string: String(describing: staticString)) else {
      fatalError("Static \(staticString) is not a valid URL")
    }
    self = url
  }
}
