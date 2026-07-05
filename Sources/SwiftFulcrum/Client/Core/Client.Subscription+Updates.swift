// Client.Subscription+Updates.swift

import Foundation

extension SwiftFulcrum.Client.Subscription {
    public struct Updates: AsyncSequence, Sendable {
        public typealias Element = Update

        private let stream: AsyncThrowingStream<Update, Swift.Error>
        private let cancellationState: SubscriptionUpdatesCancellationState

        init(
            stream: AsyncThrowingStream<Update, Swift.Error>,
            cancellationState: SubscriptionUpdatesCancellationState
        ) {
            self.stream = stream
            self.cancellationState = cancellationState
        }

        public func makeAsyncIterator() -> AsyncThrowingStream<Update, Swift.Error>.Iterator {
            stream.makeAsyncIterator()
        }

        public func cancel() async {
            await cancellationState.cancel()
        }
    }
}
