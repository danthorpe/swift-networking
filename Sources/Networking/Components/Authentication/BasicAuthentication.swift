import Foundation

extension AuthenticationMethod {
  public static let basic = AuthenticationMethod(rawValue: "Basic")
}

public struct BasicCredentials: Hashable, Sendable, AuthenticatingCredentials, HTTPRequestDataOption {
  public static var method: AuthenticationMethod = .basic
  public static let defaultOption: Self? = nil
  
  public let user: String
  public let password: String

  public init(user: String, password: String) {
    self.user = user
    self.password = password
  }

  public func apply(to request: HTTPRequestData) -> HTTPRequestData {
    var copy = request
    let joined = user + ":" + password
    let data = Data(joined.utf8)
    let encoded = data.base64EncodedString()
    copy.headerFields[.authorization] = "Basic \(encoded)"
    return copy
  }
}

extension HTTPRequestData {
  public var basicCredentials: BasicCredentials? {
    get { self[option: BasicCredentials.self] }
    set { self[option: BasicCredentials.self] = newValue }
  }
}

public typealias BasicAuthentication<
  Delegate: AuthenticationDelegate
> = HeaderBasedAuthentication<Delegate> where Delegate.Credentials == BasicCredentials
