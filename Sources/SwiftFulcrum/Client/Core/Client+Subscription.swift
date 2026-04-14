// Client+Subscription.swift

import Foundation

extension SwiftFulcrum.Client {
    /// Represents an active subscription, including the initial response, update stream, and cancellation handle.
    public struct Subscription<Initial: Sendable, Update: Sendable>: Sendable {
        public let initial: Initial
        public let updates: AsyncThrowingStream<Update, Swift.Error>

        private let cancellationHandler: @Sendable () async -> Void

        init(
            initial: Initial,
            updates: AsyncThrowingStream<Update, Swift.Error>,
            cancellationHandler: @escaping @Sendable () async -> Void
        ) {
            self.initial = initial
            self.updates = updates
            self.cancellationHandler = cancellationHandler
        }

        /// Cancels the subscription and finishes its update stream.
        public func cancel() async {
            await cancellationHandler()
        }
    }
}
