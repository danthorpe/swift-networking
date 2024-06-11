import Foundation

extension NetworkingError {

  public func decodeResponseBody<ErrorMessage: Decodable>(
    as errorMessageType: ErrorMessage.Type,
    using decoder: some Decoding<Data>
  ) -> ErrorMessage? {
    guard let response, false == response.data.isEmpty else {
      return nil
    }
    do {
      let message = try decoder.decode(errorMessageType, from: response.data)
      return message
    } catch {
      @NetworkEnvironment(\.logger) var logger
      if let logger {
        let stringRepresentation = String(decoding: response.data, as: UTF8.self)
        let privateLogMessage =
          "Decoding \(String(describing: response))"
          + " into \(String(describing: errorMessageType)),"
          + " but received: \(stringRepresentation)"
        logger.error("Failed to decode error message. \(privateLogMessage, privacy: .private)")
      }
      return nil
    }
  }

  public func decodeResponseBodyIntoJSON<ErrorMessage: Decodable>(
    as errorMessageType: ErrorMessage.Type
  ) -> ErrorMessage? {
    decodeResponseBody(as: errorMessageType, using: JSONDecoder())
  }
}
