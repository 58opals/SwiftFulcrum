// Client.Diagnostics+Snapshot.swift

import Foundation

extension SwiftFulcrum.Client.Diagnostics {
    public struct Snapshot: Sendable {
        public let reconnectAttempts: Int
        public let reconnectSuccesses: Int
        public let inflightUnaryCallCount: Int
        public let activeSubscriptionCount: Int

        public init(
            reconnectAttempts: Int,
            reconnectSuccesses: Int,
            inflightUnaryCallCount: Int,
            activeSubscriptionCount: Int
        ) {
            self.reconnectAttempts = reconnectAttempts
            self.reconnectSuccesses = reconnectSuccesses
            self.inflightUnaryCallCount = inflightUnaryCallCount
            self.activeSubscriptionCount = activeSubscriptionCount
        }
    }
}
