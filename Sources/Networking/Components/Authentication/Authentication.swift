import Helpers

extension NetworkingComponent {
  public func authenticated<Delegate: AuthenticationDelegate>(with delegate: Delegate) -> some NetworkingComponent {
    checkedStatusCode().modified(Authentication(delegate: delegate))
  }
}

struct Authentication<Delegate: AuthenticationDelegate>: NetworkingModifier {
  typealias Credentials = Delegate.Credentials
  let delegate: Delegate

  func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    guard let method = request.authenticationMethod, method == Credentials.method else {
      return upstream.send(request)
    }
    return ResponseStream { continuation in
      Task {

        // Fetch the initial credentials
        var credentials: Credentials
        do {
          credentials = try await delegate.fetch(for: request)
        } catch let error as AuthenticationError {
          continuation.finish(
            throwing: error
          )
          return
        } catch {
          continuation.finish(
            throwing: AuthenticationError.fetchCredentialsFailed(request, Credentials.method, error)
          )
          return
        }

        // Update the request to use the credentials
        let newRequest = credentials.apply(to: request)

        // Process the stream
        do {
          for try await event in upstream.send(newRequest) {
            continuation.yield(event)
          }
          continuation.finish()
        } catch let StackError.unauthorized(response) {
          let newRequest = try await refresh(
            unauthorized: &credentials,
            response: response,
            continuation: continuation
          )
          await upstream.send(newRequest).redirect(into: continuation)
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  func refresh(
    unauthorized credentials: inout Credentials,
    response: HTTPResponseData,
    continuation: ResponseStream<HTTPResponseData>.Continuation
  ) async throws -> HTTPRequestData {
    do {
      credentials = try await delegate.refresh(unauthorized: credentials, from: response)
      return credentials.apply(to: response.request)
    } catch let error as AuthenticationError {
      throw error
    } catch {
      throw AuthenticationError.refreshCredentialsFailed(response, Credentials.method, error)
    }
  }
}

public enum AuthenticationError: Error {
  case fetchCredentialsFailed(HTTPRequestData, AuthenticationMethod, Error)
  case refreshCredentialsFailed(HTTPResponseData, AuthenticationMethod, Error)
}

extension AuthenticationError: Equatable {
  public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
    switch (lhs, rhs) {
    case let (.fetchCredentialsFailed(lhsR, lhsAM, lhsE), .fetchCredentialsFailed(rhsR, rhsAM, rhsE)):
      return lhsR == rhsR && lhsAM == rhsAM && _isEqual(lhsE, rhsE)
    case let (.refreshCredentialsFailed(lhsR, lhsAM, lhsE), .refreshCredentialsFailed(rhsR, rhsAM, rhsE)):
      return lhsR == rhsR && lhsAM == rhsAM && _isEqual(lhsE, rhsE)
    default:
      return false
    }
  }
}

extension AuthenticationError: NetworkingError {
  public var request: HTTPRequestData {
    switch self {
    case let .fetchCredentialsFailed(request, _, _):
      return request
    case let .refreshCredentialsFailed(response, _, _):
      return response.request
    }
  }

  public var response: HTTPResponseData? {
    switch self {
    case .fetchCredentialsFailed:
      return nil
    case let .refreshCredentialsFailed(response, _, _):
      return response
    }
  }
}
