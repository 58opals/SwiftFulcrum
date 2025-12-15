// Fulcrum+ConnectionState.swift

import Foundation

extension Fulcrum {
    public enum ConnectionState: Equatable {
        case idle
        case connecting
        case connected
        case disconnected
        case reconnecting
    }
}

extension Fulcrum {
    public var connectionState: ConnectionState { currentConnectionState }
    
    public func makeConnectionStateStream() -> AsyncStream<ConnectionState> {
        if let sharedConnectionStateStream { return sharedConnectionStateStream }
        
        let stream = AsyncStream<ConnectionState> { continuation in
            self.connectionStateContinuation = continuation
            continuation.yield(currentConnectionState)
            continuation.onTermination = { @Sendable [weak self] _ in
                guard let self else { return }
                Task { await self.resetConnectionStateStream() }
            }
        }
        
        sharedConnectionStateStream = stream
        return stream
    }
}

extension Fulcrum {
    func startConnectionStateObservation() {
        connectionStateObservationTask?.cancel()
        connectionStateObservationTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.client.makeConnectionStateEvents()
            for await webSocketState in stream {
                await self.updateConnectionState(mapped(from: webSocketState))
            }
        }
    }
    
    func updateConnectionState(_ state: ConnectionState) async {
        guard currentConnectionState != state else { return }
        currentConnectionState = state
        connectionStateContinuation?.yield(state)
    }
    
    func resetConnectionStateStream() async {
        sharedConnectionStateStream = nil
        connectionStateContinuation = nil
    }
    
    func mapped(from webSocketState: WebSocket.ConnectionState) -> ConnectionState {
        switch webSocketState {
        case .idle: .idle
        case .connecting: .connecting
        case .connected: .connected
        case .disconnected: .disconnected
        case .reconnecting: .reconnecting
        }
    }
}
