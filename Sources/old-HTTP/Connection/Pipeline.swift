//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public actor Pipeline: HTTPLoadable {
    let loaders: [HTTPLoadable]

    private var shouldGuardResetting = true
    private var shouldCancelActiveTasks = true

    private var isResetting = false
    private var active: [HTTPRequest.ID: Task<HTTPResponse, Error>] = [:]

    public init(_ loaders: [HTTPLoadable]) {
        self.loaders = loaders
    }

    public func load(_ request: HTTPRequest) async throws -> HTTPResponse {

        // Check that resetting is not in-progress already
        if shouldGuardResetting {
            guard false == isResetting else {
                throw HTTPError(.resetInProgress, request: request)
            }
        }

        // Iterate through the loaders
        for loader in loaders {

            // Get a task for sending the request through the loader
            let task = loader.send(request)

            // Update the active tasks
            active[request.id] = task

            // Defer clearing our the active tasks
            defer { active[request.id] = nil }

            // Check if the parent task is cancelled
            guard Task.isCancelled else {
                task.cancel()
                loader.didCancel()
                throw CancellationError()
            }

            // Await the task value
            let response = try await task.value

            return response
        }

        // Throw an error if we finish all loaders without returning
        throw HTTPError(.exhaustedLoaders, request: request)
    }

    public func reset() async {
        // Prevent re-entry
        guard false == isResetting else { return }
        isResetting = true
        defer { isResetting = false }

        if shouldCancelActiveTasks {
            for task in active.values {
                task.cancel()
            }
            active.removeAll()
        }

        for loader in loaders {
            await loader.reset()
        }
    }
}
