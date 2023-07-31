import Combine
import Dependencies
import Foundation
import HTTPTypes
import Helpers
import Tagged
import ShortID

public struct HTTPRequestData: Sendable, Identifiable {
    public typealias ID = Tagged<Self, String>
    public let id: ID
    public var body: Data?
    fileprivate var _request: HTTPRequest

    private var options: [ObjectIdentifier: HTTPRequestDataOptionContainer] = [:]

    public init(
        id: ID,
        method: HTTPRequest.Method,
        scheme: String?,
        authority: String?,
        path: String?,
        headerFields: HTTPFields = [:],
        body: Data? = nil
    ) {
        self.id = id
        self.body = body
        self._request = .init(
            method: method,
            scheme: scheme,
            authority: authority,
            path: path,
            headerFields: headerFields
        )
    }

    public init(
        method: HTTPRequest.Method,
        scheme: String?,
        authority: String?,
        path: String?,
        headerFields: HTTPFields = [:],
        body: Data? = nil
    ) {
        @Dependency(\.shortID) var shortID
        self.init(
            id: .init(shortID().description),
            method: method,
            scheme: scheme,
            authority: authority,
            path: path
        )
    }
}

// MARK: - HTTPRequest Conveniences

extension HTTPRequestData {

    public var method: HTTPRequest.Method {
        get { _request.method }
        set { _request.method = newValue }
    }

    public var scheme: String? {
        get { _request.scheme }
        set { _request.scheme = newValue }
    }

    public var authority: String? {
        get { _request.authority }
        set { _request.authority = newValue }
    }

    public var path: String? {
        get { _request.path }
        set { _request.path = newValue }
    }

    public var extendedConnectProtocol: String? {
        get { _request.extendedConnectProtocol }
        set { _request.extendedConnectProtocol = newValue }
    }

    public var pseudoHeaderFields: HTTPRequest.PseudoHeaderFields {
        get { _request.pseudoHeaderFields }
        set { _request.pseudoHeaderFields = newValue }
    }

    public var headerFields: HTTPFields {
        get { _request.headerFields }
        set { _request.headerFields = newValue }
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
            options[id] = HTTPRequestDataOptionContainer(newValue, isEqualTo: { other in
                optionType.includeInEqualityEvaluation ? _isEqual(newValue, other) : true
            })
        }
    }
}

// MARK: - Conformances

extension HTTPRequestData: Equatable {
    public static func == (lhs: HTTPRequestData, rhs: HTTPRequestData) -> Bool {
        lhs.body == rhs.body
        && lhs._request == rhs._request
        && lhs.options.allSatisfy { key, lhs in
            guard let rhs = rhs.options[key] else { return false }
            return lhs.isEqualTo(rhs)
        }
    }
}

extension HTTPRequestData: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(body)
        hasher.combine(_request)
    }
}

extension HTTPRequestData: CustomStringConvertible {
    public var description: String {
        let prefix = "\(RequestSequence.number):\(id.rawValue)"
        return "\(prefix) \(_request.authority ?? "/")\(_request.path ?? "")"
    }
}

// MARK: - Foundation

extension URLRequest {
    init?(http: HTTPRequestData) {
        self.init(httpRequest: http._request)
    }
}
