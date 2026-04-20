// Client+ConnectionState.swift

import Foundation

extension SwiftFulcrum.Client {
    public enum ConnectionState: Equatable, Sendable {
        case idle
        case connecting
        case connected
        case disconnected
        case reconnecting
    }
}

extension SwiftFulcrum.Client {
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

extension SwiftFulcrum.Client {
    func startConnectionStateObservation() {
        connectionStateObservationTask?.cancel()
        let client = self.client
        let owner = self
        connectionStateObservationTask = Task {
            let stream = await client.makeConnectionStateEvents()
            for await state in stream {
                await owner.updateConnectionState(state)
            }
        }
    }

    func stopConnectionStateObservation() async {
        connectionStateObservationTask?.cancel()
        await connectionStateObservationTask?.value
        connectionStateObservationTask = nil
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
