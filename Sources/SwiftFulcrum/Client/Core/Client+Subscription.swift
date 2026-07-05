// Client+Subscription.swift

import Foundation

extension SwiftFulcrum.Client {
    /// Represents an active subscription, including the initial response, update stream, and cancellation handle.
    public struct Subscription<Initial: Sendable, Update: Sendable>: Sendable {
        public let initial: Initial
        public let updates: Updates

        init(
            initial: Initial,
            updates: Updates
        ) {
            self.initial = initial
            self.updates = updates
        }

        /// Cancels the subscription and finishes its update stream.
        public func cancel() async {
            await updates.cancel()
        }
    }
}
