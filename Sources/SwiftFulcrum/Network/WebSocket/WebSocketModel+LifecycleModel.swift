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
        if let stream = sharedLifecycleStream { return stream }
        let stream = AsyncStream<LifecycleModel.EventModel> { continuation in
            self.lifecycleContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.resetLifecycleStream() }
            }
        }
        
        sharedLifecycleStream = stream
        return stream
    }
    
    func emitLifecycle(_ event: LifecycleModel.EventModel) {
        lifecycleContinuation?.yield(event)
    }
    
    private func resetLifecycleStream() async {
        sharedLifecycleStream = nil
        lifecycleContinuation = nil
    }
}
