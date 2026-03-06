import Foundation

extension SwiftFulcrum.Logging {
    public static func perform<T>(
        withBehavior behavior: Behavior,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        try await Context.$behavior.withValue(behavior) {
            try await operation()
        }
    }
}
