import Algorithms
import Combine
import Dependencies
import Foundation
import HTTPTypes
import Helpers
import ShortID
import Tagged

@dynamicMemberLookup
public struct HTTPRequestData: Sendable, Identifiable {
  public typealias ID = Tagged<Self, String>
  public let id: ID
  public var body: Data?

  @Sanitized fileprivate var request: HTTPRequest
  internal fileprivate(set) var options: [ObjectIdentifier: HTTPRequestDataOptionContainer] = [:]

  public var identifier: String {
    id.rawValue
  }

  public subscript<Value>(
    dynamicMember dynamicMember: WritableKeyPath<HTTPRequest, Value>
  ) -> Value {
    get { $request[keyPath: dynamicMember] }
    set { $request[keyPath: dynamicMember] = newValue }
  }

  init(
    id: ID,
    method: HTTPRequest.Method = .get,
    scheme: String? = "https",
    authority: String? = nil,
    path: String? = nil,
    headerFields: HTTPFields = [:],
    body: Data? = nil
  ) {
    self.id = id
    self.body = body
    self._request = .init(
      projectedValue: .init(
        method: method,
        scheme: scheme,
        authority: authority,
        path: path,
        headerFields: headerFields
      ))
  }

  public init(
    method: HTTPRequest.Method = .get,
    scheme: String? = "https",
    authority: String? = nil,
    path: String? = nil,
    headerFields: HTTPFields = [:],
    body: Data? = nil
  ) {
    @Dependency(\.shortID) var shortID
    self.init(
      id: .init(shortID().description),
      method: method,
      scheme: scheme,
      authority: authority,
      path: path,
      headerFields: headerFields,
      body: body
    )
  }

  public init(
    method: HTTPRequest.Method = .get,
    scheme: String? = "https",
    authority: String? = nil,
    path: String? = nil,
    headerFields: HTTPFields = [:],
    body: any HTTPRequestBody
  ) throws {
    var fields = headerFields
    let data: Data? = try {
      guard body.isNotEmpty else {
        return nil
      }
      fields.append(body.additionalHeaders)
      return try body.encode()
    }()
    self.init(
      method: method,
      scheme: scheme,
      authority: authority,
      path: path,
      headerFields: fields,
      body: data
    )
  }
}

// MARK: - Options

extension HTTPRequestData {
  public subscript<Option: HTTPRequestDataOption>(option optionType: Option.Type) -> Option.Value {
    get {
      let id = ObjectIdentifier(optionType)
      guard let container = options[id], let value = container.value as? Option.Value else {
        return optionType.defaultOption
      }
      return value
    }
    set {
      let id = ObjectIdentifier(optionType)
      options[id] = HTTPRequestDataOptionContainer(
        newValue,
        isEqualTo: { other in
          guard let other else {
            return false == optionType.includeInEqualityEvaluation
          }
          return optionType.includeInEqualityEvaluation
            ? _isEqual(newValue, other)
            : true
        })
    }
  }

  internal mutating func copy(options other: [ObjectIdentifier: HTTPRequestDataOptionContainer]) {
    self.options = other
  }
}

// MARK: - Conformances

extension HTTPRequestData: Equatable {
  public static func == (lhs: HTTPRequestData, rhs: HTTPRequestData) -> Bool {
    lhs.id == rhs.id
      && lhs.body == rhs.body
      && lhs.request == rhs.request
      && lhs.options.allSatisfy { key, lhs in
        lhs.isEqualTo(rhs.options[key]?.value)
      }
      && rhs.options.allSatisfy { key, rhs in
        rhs.isEqualTo(lhs.options[key]?.value)
      }
  }
}

extension HTTPRequestData: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(body)
    hasher.combine(request)
  }
}

extension HTTPRequestData: CustomDebugStringConvertible {
  public var debugDescription: String {
    "[\(RequestSequence.number):\(identifier)] \(request.debugDescription)"
  }
}

// MARK: - Pattern Match

public func ~= (lhs: HTTPRequestData, rhs: HTTPRequestData) -> Bool {
  lhs.body == rhs.body
    && (lhs.request == rhs.request)
    && lhs.options.allSatisfy { key, lhs in
      lhs.isEqualTo(rhs.options[key]?.value)
    }
    && rhs.options.allSatisfy { key, rhs in
      rhs.isEqualTo(lhs.options[key]?.value)
    }
}

// MARK: - Sanitize

@propertyWrapper
private struct Sanitized {
  var projectedValue: HTTPRequest
  var wrappedValue: HTTPRequest {
    projectedValue.sanitized()
  }
}

extension HTTPRequest {
  fileprivate func sanitized() -> Self {
    var copy = self
    copy.sanitize()
    return copy
  }

  fileprivate mutating func sanitize() {
    // Trim any trailing / from authority
    authority = authority?.trimSlashSuffix()
    // Ensure there is a single / on the path
    if let trimmedPath = path?.trimSlashPrefix(), !trimmedPath.isEmpty {
      path = "/" + trimmedPath
    }

    if let path, path.isEmpty {
      self.path = "/"
    } else if nil == path {
      self.path = "/"
    }
  }
}

extension String {
  fileprivate mutating func trimSlashSuffix() -> String {
    String(self.trimmingSuffix(while: { $0 == "/" }))
  }
  fileprivate mutating func trimSlashPrefix() -> String {
    String(self.trimmingPrefix(while: { $0 == "/" }))
  }
}

// MARK: - Foundation

extension URLRequest {
  public init?(http: HTTPRequestData) {
    self.init(httpRequest: http.request)
  }
}
