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
    final class ConnectionStateTracker {
        private(set) var state: ConnectionState = .idle
        
        private var sharedStream: AsyncStream<ConnectionState>?
        private var continuation: AsyncStream<ConnectionState>.Continuation?
        
        func makeStream() -> AsyncStream<ConnectionState> {
            if let sharedStream { return sharedStream }
            
            let stream = AsyncStream<ConnectionState> { [weak self] continuation in
                guard let self else { return }
                self.continuation = continuation
                continuation.yield(self.state)
                continuation.onTermination = { @Sendable [weak self] _ in
                    self?.reset()
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
        
        private func reset() {
            sharedStream = nil
            continuation = nil
        }
    }
}
