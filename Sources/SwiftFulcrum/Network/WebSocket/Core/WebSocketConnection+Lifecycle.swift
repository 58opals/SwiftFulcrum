// WebSocketConnection+Lifecycle.swift

import Foundation

extension WebSocketConnection {
    func makeLifecycleEvents() -> AsyncStream<Lifecycle.Event> {
        let subscriberIdentifier = UUID()
        let stream = AsyncStream<Lifecycle.Event> { continuation in
            self.storeLifecycleContinuation(
                continuation,
                forSubscriberIdentifier: subscriberIdentifier
            )
        }

        return stream
    }

    func emitLifecycle(_ event: Lifecycle.Event) {
        for continuation in lifecycleContinuationsBySubscriberIdentifier.values {
            continuation.yield(event)
        }
    }

    private func storeLifecycleContinuation(
        _ continuation: AsyncStream<Lifecycle.Event>.Continuation,
        forSubscriberIdentifier subscriberIdentifier: UUID
    ) {
        lifecycleContinuationsBySubscriberIdentifier[subscriberIdentifier] = continuation
        continuation.onTermination = { @Sendable [weak self] _ in
            Task { await self?.removeLifecycleContinuation(forSubscriberIdentifier: subscriberIdentifier) }
        }
    }

    private func removeLifecycleContinuation(forSubscriberIdentifier subscriberIdentifier: UUID) {
        lifecycleContinuationsBySubscriberIdentifier.removeValue(forKey: subscriberIdentifier)
    }
}
