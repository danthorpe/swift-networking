//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation
import URLRouting

public protocol HTTPLoadable {

    /// Primary function which requires implementing, to process
    /// the ``URLRequestData`` and asynchronously return either a
    /// ``HTTPLoadableResponse.continue`` which indicates that the
    /// next loader in the chain has work to perform. Or alternativly
    /// return ``HTTPLoadableResponse.end`` with an ``HTTPResponse``
    /// which stops further loading, and is typically the terminal
    /// loader (e.g. ``TransportLoader`` using ``URLSession``).
    func load(_ request: URLRequestData) -> Task<(Data, URLResponse), Error>

    /// Perform any clean-up to clear any state
    func reset() async

    /// Perform any clean-up after cancellation for an in-flight loadable
    func didCancel()
}


/// MARK: - Public conveniences

public extension HTTPLoadable {

    func checkCancellation() throws {
        try Task.checkCancellation()
    }
}

/// MARK: - Default Implementations

public extension HTTPLoadable {

    /// The default implementation calls out to
    /// ``defaultReset()`` which in turn does nothing.
    func reset() async {
        await defaultReset()
    }

    func didCancel() {
        defaultDidCancel()
    }

    /// The default reset implementation currently
    /// does nothing.
    func defaultReset() async { /* Currently no-op */ }

    /// The default did cancel implementation currently
    /// does nothing.
    func defaultDidCancel() { /* Currently no-op */ }
}
