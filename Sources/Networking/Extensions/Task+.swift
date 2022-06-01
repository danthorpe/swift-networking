import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds timeInterval: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
    }
}

