// WebSocketModel+ConnectionStateTrackerModel.swift

import Foundation

extension WebSocketModel {
    actor ConnectionStateTrackerModel {
        private(set) var state: ConnectionState = .idle
        private var continuationsBySubscriberIdentifier: [UUID: AsyncStream<ConnectionState>.Continuation] = .init()

        func makeStream() -> AsyncStream<ConnectionState> {
            let subscriberIdentifier = UUID()
            let stream = AsyncStream<ConnectionState> { continuation in
                self.storeContinuation(continuation, forSubscriberIdentifier: subscriberIdentifier)
            }

            return stream
        }

        func update(to newState: ConnectionState) {
            guard state != newState else { return }
            state = newState

            for continuation in continuationsBySubscriberIdentifier.values {
                continuation.yield(newState)
            }
        }

        private func storeContinuation(
            _ continuation: AsyncStream<ConnectionState>.Continuation,
            forSubscriberIdentifier subscriberIdentifier: UUID
        ) {
            continuationsBySubscriberIdentifier[subscriberIdentifier] = continuation
            continuation.yield(state)
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.removeContinuation(forSubscriberIdentifier: subscriberIdentifier) }
            }
        }

        private func removeContinuation(forSubscriberIdentifier subscriberIdentifier: UUID) {
            continuationsBySubscriberIdentifier.removeValue(forKey: subscriberIdentifier)
        }
    }
}
