//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public struct FormBody: HTTPBody {

    private let values: [URLQueryItem]

    public let additionalHeaders: [String : String] = [
        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
    ]

    public var isEmpty: Bool { values.isEmpty }

    public init(_ values: [URLQueryItem]) {
        self.values = values
    }

    public init(_ values: [String: String]) {
        let items = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        self.init(items)
    }

    public init(_ values: KeyValuePairs<String, String>) {
        let items = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        self.init(items)
    }

    public func encode() throws -> Data {
        let parts = values.map(encode(queryItem:))
        let body = parts.joined(separator: "&")
        return Data(body.utf8)
    }

    private func encode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    }

    private func encode(queryItem: URLQueryItem) -> String {
        let name = encode(queryItem.name)
        let value = encode(queryItem.value ?? "")
        return "\(name)=\(value)"
    }
}
