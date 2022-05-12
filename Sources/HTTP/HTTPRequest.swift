//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Concurrency
import Foundation
import Tagged

private extension UUID {
    static let empty = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
}

public struct HTTPRequest: Identifiable {

    public typealias ID = Tagged<HTTPRequest, UUID>

    private struct State {
        var method: HTTPMethod = .get
        var components = URLComponents()
        var options = [ObjectIdentifier: Any]()
        var headers: [String: String] = [:]
    }

    public internal(set) var id: ID = .init(rawValue: UUID.empty)

    public internal(set) var number: Int = Int.min

    public var body: HTTPBody = EmptyBody()

    @Protected
    private var state = State()

    public init() {
        components.scheme = "https"
    }
}

extension HTTPRequest: Hashable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id &&
        lhs.method == rhs.method &&
        lhs.headers == rhs.headers &&
        lhs.components == rhs.components
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(method)
        hasher.combine(headers)
        hasher.combine(components)
    }
}

public extension HTTPRequest {

    var method: HTTPMethod {
        get { $state.read { $0.method } }
        set { $state.write { $0.method = newValue } }
    }

    var headers: [String: String] {
        get { $state.read { $0.headers } }
        set { $state.write { $0.headers = newValue } }
    }

    subscript(header key: String) -> String? {
        get { $state.read { $0.headers[key] } }
        set { $state.write { $0.headers[key] = newValue } }
    }

    subscript<Option: HTTPRequestOption>(option type: Option.Type) -> Option.Value {
        get {
            let key = ObjectIdentifier(type)
            return $state.read { ward in
                guard let value = ward.options[key] as? Option.Value else {
                    return type.defaultValue
                }
                return value
            }
        }
        set {
            let key = ObjectIdentifier(type)
            $state.write { $0.options[key] = newValue }
        }
    }
}

public extension HTTPRequest {

    private var components: URLComponents {
        get { $state.read { $0.components } }
        set { $state.write { $0.components = newValue } }
    }

    var scheme: String {
        components.scheme ?? "https"
    }

    var url: URL? {
        components.url
    }

    var host: String? {
        get { components.host }
        set { $state.write { $0.components.host = newValue } }
    }

    var path: String {
        get { components.path }
        set { $state.write { $0.components.path = newValue } }
    }
}

extension HTTPRequest: CustomStringConvertible {

    public var description: String {
        "\(method.name) \(host ?? "") \(path)"
    }
}
