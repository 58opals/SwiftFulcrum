// WebSocketModel+LifecycleModel.swift

import Foundation

extension WebSocketModel {
    enum LifecycleModel {}
}

extension WebSocketModel.LifecycleModel {
    enum EventModel: Sendable {
        case connected(isReconnect: Bool)
        case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    }
}

extension WebSocketModel {
    func makeLifecycleEvents() -> AsyncStream<LifecycleModel.EventModel> {
        let subscriberIdentifier = UUID()
        let stream = AsyncStream<LifecycleModel.EventModel> { continuation in
            self.storeLifecycleContinuation(
                continuation,
                forSubscriberIdentifier: subscriberIdentifier
            )
        }

        return stream
    }
    
    func emitLifecycle(_ event: LifecycleModel.EventModel) {
        for continuation in lifecycleContinuationsBySubscriberIdentifier.values {
            continuation.yield(event)
        }
    }
    
    private func storeLifecycleContinuation(
        _ continuation: AsyncStream<LifecycleModel.EventModel>.Continuation,
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
