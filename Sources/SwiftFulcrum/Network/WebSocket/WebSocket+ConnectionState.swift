// WebSocket+ConnectionState.swift

import Foundation

extension WebSocket {
    enum ConnectionState: Equatable {
        case idle
        case connecting
        case connected
        case disconnected
        case reconnecting
    }
}

extension WebSocket {
    actor ConnectionStateTracker {
        private(set) var state: ConnectionState = .idle
        
        private var sharedStream: AsyncStream<ConnectionState>?
        private var continuation: AsyncStream<ConnectionState>.Continuation?
        
        func makeStream() -> AsyncStream<ConnectionState> {
            if let sharedStream { return sharedStream }
            
            let stream = AsyncStream<ConnectionState> { continuation in
                Task { [weak self] in
                    guard let self else { return }
                    await self.storeContinuation(continuation)
                }
            }
            
            sharedStream = stream
            return stream
        }
        
        func update(to newState: ConnectionState) {
            guard state != newState else { return }
            state = newState
            continuation?.yield(newState)
        }
        
        private func storeContinuation(_ continuation: AsyncStream<ConnectionState>.Continuation) async {
            self.continuation = continuation
            continuation.yield(state)
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { await self?.reset() }
            }
        }
        
        private func reset() {
            sharedStream = nil
            continuation = nil
        }
    }
}
