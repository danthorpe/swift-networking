import Foundation

private enum QueryItemsAllowedCharacters: HTTPRequestDataOption {
  public static let defaultOption: CharacterSet = .urlQueryAllowed
}

extension HTTPRequestData {
  public var queryItemsAllowedCharacters: CharacterSet {
    get { self[option: QueryItemsAllowedCharacters.self] }
    set {
      self[option: QueryItemsAllowedCharacters.self] = newValue
      self.percentEncodeQueryItems()
    }
  }
}
