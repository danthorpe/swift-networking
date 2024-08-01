import Algorithms
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

  fileprivate var _queryItems: [URLQueryItem]?
  @Sanitized fileprivate var request: HTTPRequest
  internal fileprivate(set) var options: [ObjectIdentifier: HTTPRequestDataOptionContainer] = [:]

  public var identifier: String {
    id.rawValue
  }

  public var method: HTTPRequest.Method {
    get { request.method }
    set { $request.method = newValue }
  }

  public var scheme: String {
    get { request.scheme ?? Defaults.scheme }
    set { $request.scheme = newValue }
  }

  public var authority: String {
    get { request.authority ?? Defaults.authority }
    set { $request.authority = newValue }
  }

  public var port: Int? {
    components.port
  }

  public var path: String {
    get { request.path ?? Defaults.path }
    set {
      $request.path = newValue

      // Check to see if the new path included query items
      if let newPathBasedQueryItems = components.queryItems {
        _queryItems = newPathBasedQueryItems
      } else {
        let queryItems = _queryItems
        mutateViaComponents { $0.queryItems = queryItems }
      }
    }
  }

  public var queryItems: [URLQueryItem]? {
    get { _queryItems }
    set {
      _queryItems = newValue
      mutateViaComponents { $0.percentEncodedQueryItems = newValue }
    }
  }

  public var headerFields: HTTPFields {
    get { request.headerFields }
    set { $request.headerFields = newValue }
  }

  public var url: URL? {
    get { request.url }
    set {
      $request.url = newValue
      syncFromComponents()
    }
  }

  /// Get/Set the query items, will replace an existing value for the same name
  public subscript(
    dynamicMember key: String
  ) -> String? {
    get {
      queryItems?.first(where: { $0.name == key })?.value
    }
    set {
      var copy = queryItems
      // Remove all to start with
      copy?.removeAll(where: { $0.name == key })
      guard let newValue else { return }
      let queryItem = URLQueryItem(name: key, value: newValue)
        .addingPercentEncoding(withAllowedCharacters: _queryItemsAllowedCharacters)
      copy.append(queryItem)
      copy?.sort(by: { $0.name < $1.name })
      queryItems = copy
    }
  }

  init(
    id: ID,
    body: Data?,
    request: HTTPRequest
  ) {
    self.id = id
    self.body = body
    self._request = .init(projectedValue: request)
    syncFromComponents()
  }

  init(
    id: ID,
    method: HTTPRequest.Method = Defaults.method,
    scheme: String = Defaults.scheme,
    authority: String = Defaults.authority,
    path: String = Defaults.path,
    headerFields: HTTPFields = [:],
    body: Data? = nil
  ) {
    self.init(
      id: id,
      body: body,
      request: .init(
        method: method,
        scheme: scheme,
        authority: authority,
        path: path,
        headerFields: headerFields
      )
    )
  }

  public init(
    method: HTTPRequest.Method = Defaults.method,
    scheme: String = Defaults.scheme,
    authority: String = Defaults.authority,
    path: String = Defaults.path,
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
    method: HTTPRequest.Method = Defaults.method,
    scheme: String = Defaults.scheme,
    authority: String = Defaults.authority,
    path: String = Defaults.path,
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

  public enum Defaults {
    public static let method: HTTPRequest.Method = .get
    public static let scheme = "https"
    public static let authority = "example.com"
    public static let path = "/"
    public static let queryItemsAllowedCharacters = CharacterSet.urlQueryAllowed
      .subtracting(CharacterSet(charactersIn: "&="))
  }

  private var _queryItemsAllowedCharacters: CharacterSet {
    queryItemsAllowedCharacters.intersection(Defaults.queryItemsAllowedCharacters)
  }

  private var components: URLComponents {
    guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      assertionFailure("Unable to create URL or URLComponents needed to set the query")
      return URLComponents()
    }
    return components
  }

  private mutating func mutateViaComponents(_ block: (inout URLComponents) -> Void) {
    var copy = components
    block(&copy)
    guard let url = copy.url else {
      assertionFailure("Unable to create URL after mutating components \(copy)")
      return
    }
    $request.url = url
  }

  internal mutating func syncFromComponents() {
    let components = self.components
    _queryItems = components.percentEncodedQueryItems
  }

  internal mutating func percentEncodeQueryItems() {
    let encodedQueryItems = components.queryItems?
      .map {
        $0.addingPercentEncoding(withAllowedCharacters: _queryItemsAllowedCharacters)
      }
    _queryItems = encodedQueryItems
    mutateViaComponents {
      $0.percentEncodedQueryItems = encodedQueryItems
    }
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
    "[\(prettyPrintedIdentifier)] \(request.debugDescription)"
  }
}

// MARK: - Logging Helpers

extension HTTPRequestData {
  public var prettyPrintedIdentifier: String {
    "\(RequestSequence.number):\(identifier)"
  }

  public var prettyPrintedHeaders: String {
    headerFields.prettyPrintedDescription(title: "📮 Request Headers")
  }

  public var prettyPrintedBody: String {
    body?.prettyPrintedData ?? "No data"
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
    // Remove any trailing slashes from the path
    path = path?.trimSlashSuffix()
    // Ensure there is a single / on the start of path
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
    self.httpBody = http.body
  }
}

extension URLQueryItem {
  func addingPercentEncoding(withAllowedCharacters characters: CharacterSet) -> URLQueryItem {
    URLQueryItem(
      name: name.addingPercentEncoding(withAllowedCharacters: characters) ?? name,
      value: value?.addingPercentEncoding(withAllowedCharacters: characters)
    )
  }
}
