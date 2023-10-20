/// A system which can asynchronously fetch or refresh credentials
/// in order to make authenticated HTTP requests
public protocol AuthenticationDelegate<Credentials>: Sendable {  // swiftlint:disable:this class_delegate_protocol

  /// A type which represents the credentials to be used
  associatedtype Credentials: AuthenticatingCredentials

  /// The entry point into the authentication flow
  ///
  /// Conforming types should manage their own state, providing thread safety
  /// and perform whatever actions are necessary to retreive credentials from
  /// an external system. For example - present a login interface to the user
  /// to collect a username and password.
  func fetch(for request: HTTPRequestData) async throws -> Credentials

  /// After supplying a request with credentials, it is still possible to
  /// encounter HTTP unauthorized errors. In such an event, this method will
  /// be called, allowing for a single attempt to retry with a new set of
  /// credentials. Typical usecases here would be for OAuth style refreshing
  /// of a token.
  func refresh(unauthorized: Credentials, from response: HTTPResponseData) async throws
    -> Credentials
}

public protocol AuthenticatingCredentials: Hashable, Sendable {

  /// The authentication method
  static var method: AuthenticationMethod { get }

  /// Create a new request making use of the credentials in whichever way
  /// suits their purpose. E.g. by appending a query parameter
  func apply(to request: HTTPRequestData) -> HTTPRequestData
}
