//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Concurrency
import Foundation
import Tagged
import ShortID
import URLRouting

public struct HTTPRequest: Identifiable {

    public typealias ID = Tagged<HTTPRequest, ShortID>

    public let id: ID = .init(rawValue: ShortID())

    public internal(set) var number: Int = Int.min

    @Protected
    var options = [ObjectIdentifier: Any]()

    @Protected
    public private(set) var data: URLRequestData = .init()

    public init(data: URLRequestData) {
        self.data = data
    }
}

public extension HTTPRequest {

    var method: String { data.method ?? "GET" }

    var host: String? {
        get { data.host }
        set { $data.write { $0.host = newValue } }
    }

    var path: String { "/\(data.path.joined(separator: "/"))" }

    subscript<Option: HTTPRequestOption>(option type: Option.Type) -> Option.Value {
        get {
            let key = ObjectIdentifier(type)
            return $options.read { ward in
                guard let value = ward[key] as? Option.Value else {
                    return type.defaultValue
                }
                return value
            }
        }
        set {
            let key = ObjectIdentifier(type)
            $options.write { $0[key] = newValue }
        }
    }
}


// MARK: - Conformances

extension HTTPRequest: Hashable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id &&
        lhs.number == rhs.number &&
        lhs.data == rhs.data
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(number)
        hasher.combine(data)
    }
}

extension HTTPRequest: CustomStringConvertible {

    public var description: String {
        "\(method) \(path) [\(number), \(id)]"
    }
}
