// FulcrumClient+ConnectionState.swift

import Foundation

extension FulcrumClient {
    public enum ConnectionState: Equatable, Sendable {
        case idle
        case connecting
        case connected
        case disconnected
        case reconnecting
    }
}

extension FulcrumClient {
    public var connectionState: ConnectionState { currentConnectionState }
    
    public func makeConnectionStateStream() -> AsyncStream<ConnectionState> {
        let subscriberIdentifier = UUID()
        let stream = AsyncStream<ConnectionState> { continuation in
            self.connectionStateContinuationsBySubscriberIdentifier[subscriberIdentifier] = continuation
            continuation.yield(currentConnectionState)
            continuation.onTermination = { @Sendable [weak self] _ in
                guard let self else { return }
                Task { await self.removeConnectionStateContinuation(forSubscriberIdentifier: subscriberIdentifier) }
            }
        }
        
        return stream
    }
}

extension FulcrumClient {
    func startConnectionStateObservation() {
        connectionStateObservationTask?.cancel()
        connectionStateObservationTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.client.makeConnectionStateEvents()
            for await state in stream {
                await self.updateConnectionState(state)
            }
        }
    }
    
    func updateConnectionState(_ state: ConnectionState) async {
        guard currentConnectionState != state else { return }
        currentConnectionState = state
        
        for continuation in connectionStateContinuationsBySubscriberIdentifier.values {
            continuation.yield(state)
        }
    }
    
    func resetConnectionStateStream() async {
        for continuation in connectionStateContinuationsBySubscriberIdentifier.values {
            continuation.finish()
        }
        connectionStateContinuationsBySubscriberIdentifier.removeAll(keepingCapacity: false)
    }
    
    func removeConnectionStateContinuation(forSubscriberIdentifier subscriberIdentifier: UUID) async {
        connectionStateContinuationsBySubscriberIdentifier.removeValue(forKey: subscriberIdentifier)
    }
}
