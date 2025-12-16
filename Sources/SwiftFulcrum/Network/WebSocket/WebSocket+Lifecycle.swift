// WebSocket+Lifecycle.swift

import Foundation

extension WebSocket {
    enum Lifecycle {}
}

extension WebSocket.Lifecycle {
    enum Event: Sendable {
        case connected(isReconnect: Bool)
        case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    }
}

extension WebSocket {
    func makeLifecycleEvents() -> AsyncStream<Lifecycle.Event> {
        if let stream = sharedLifecycleStream { return stream }
        let stream = AsyncStream<Lifecycle.Event> { continuation in
            self.lifecycleContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.resetLifecycleStream() }
            }
        }
        
        sharedLifecycleStream = stream
        return stream
    }
    
    func emitLifecycle(_ event: Lifecycle.Event) {
        lifecycleContinuation?.yield(event)
    }
    
    private func resetLifecycleStream() async {
        sharedLifecycleStream = nil
        lifecycleContinuation = nil
    }
}
