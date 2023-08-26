import Combine
import Dependencies
import Foundation
import HTTPTypes
import Helpers
import Tagged
import ShortID

@dynamicMemberLookup
public struct HTTPRequestData: Sendable, Identifiable {
    public typealias ID = Tagged<Self, String>
    public let id: ID
    public var body: Data?

    public var identifier: String {
        id.rawValue
    }

    public subscript<Value>(
        dynamicMember dynamicMember: WritableKeyPath<HTTPRequest, Value>
    ) -> Value {
        get { _request[keyPath: dynamicMember] }
        set { _request[keyPath: dynamicMember] = newValue }
    }

    fileprivate var _request: HTTPRequest
    fileprivate var options: [ObjectIdentifier: HTTPRequestDataOptionContainer] = [:]

    init(
        id: ID,
        method: HTTPRequest.Method = .get,
        scheme: String? = "https",
        authority: String?,
        path: String? = nil,
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
        method: HTTPRequest.Method = .get,
        scheme: String? = "https",
        authority: String?,
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
        authority: String?,
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
}

// MARK: - Conformances

extension HTTPRequestData: Equatable {
    public static func == (lhs: HTTPRequestData, rhs: HTTPRequestData) -> Bool {
        lhs.id == rhs.id
        && lhs.body == rhs.body
        && lhs._request == rhs._request
        && lhs.options.allSatisfy { key, lhs in
            return lhs.isEqualTo(rhs.options[key]?.value)
        }
        && rhs.options.allSatisfy { key, rhs in
            return rhs.isEqualTo(lhs.options[key]?.value)
        }
    }
}

extension HTTPRequestData: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(body)
        hasher.combine(_request)
    }
}

extension HTTPRequestData: CustomDebugStringConvertible {
    public var debugDescription: String {
        "[\(RequestSequence.number):\(identifier)] \(_request.debugDescription)"
    }
}

// MARK: - Pattern Match

public func ~= (lhs: HTTPRequestData, rhs: HTTPRequestData) -> Bool {
    lhs.body == rhs.body
    && lhs._request == rhs._request
    && lhs.options.allSatisfy { key, lhs in
        return lhs.isEqualTo(rhs.options[key]?.value)
    }
    && rhs.options.allSatisfy { key, rhs in
        return rhs.isEqualTo(lhs.options[key]?.value)
    }
}

// MARK: - Foundation

extension URLRequest {
    public init?(http: HTTPRequestData) {
        self.init(httpRequest: http._request)
    }
}
