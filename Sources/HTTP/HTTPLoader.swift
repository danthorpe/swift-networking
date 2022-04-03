//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation
/*


public protocol Loadable {
    associatedtype Input
    associatedtype Output
    func load(_ request: inout Input) async throws -> Output
}

public struct HTTPLoader<First, Last> where First: HTTPLoadable, Last: HTTPLoadable {
    private(set) var first: First?
    private(set) var last: Last

    public init(_ first: First, then last: Last) {
        self.init(first: first, last: last)
    }

    internal init(first: First?, last: Last) {
        self.first = first
        self.last = last
    }

    func then<Loader: HTTPLoadable>(another: Loader) -> HTTPLoader<Self, Loader> {
        .init(first: self, last: another)
    }
}

// MARK: - Conformances

extension HTTPLoader: HTTPLoadable {

    public func load(_ request: inout HTTPRequest) async throws -> HTTPLoadableResponse {
        let response = try await first?.load(&request) ?? .continue
        switch response {
        case .continue:
            return try await last.load(&request)
        default:
            return response
        }
    }
}

// MARK: - Conveniences

extension Never: HTTPLoadable {
    public func load(_ request: inout HTTPRequest) async throws -> HTTPLoadableResponse {
        fatalError("Cannot load a Never HTTPLoadable")
    }
}

extension HTTPLoader where First == Never {
    public init(_ last: Last) {
        self.init(first: nil, last: last)
    }
}

*/

open class HTTPLoader_ {

    public var next: HTTPLoader_? {
        willSet {
            guard next == nil else {
                fatalError("The nextLoader can only be set once in \(String(describing: self))")
            }
        }
    }

    public init() { }

    open func load(request: HTTPRequest) async throws -> HTTPResponse {
        guard let next = next else {
            throw HTTPError(.cannotConnect, request: request)
        }
        return try await next.load(request: request)
    }

    open func reset() async {
        await next?.reset()
    }
}
