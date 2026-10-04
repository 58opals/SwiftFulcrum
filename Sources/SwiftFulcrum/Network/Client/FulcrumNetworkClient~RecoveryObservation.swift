import Foundation

extension FulcrumNetworkClient {
    func makeConnectionRecoveryStream() -> AsyncStream<SwiftFulcrum.Client.ConnectionRecoveryObservation> {
        let identifier = UUID()
        return AsyncStream { continuation in
            recoveryObservationContinuations[identifier] = continuation
            continuation.yield(recoveryObservation)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeRecoveryObservation(identifier) }
            }
        }
    }

    var recoveryObservation: SwiftFulcrum.Client.ConnectionRecoveryObservation {
        .init(generation: connectionRecoveryGeneration, sequence: recoveryObservationSequence, state: recoveryObservationState)
    }

    func removeRecoveryObservation(_ identifier: UUID) {
        recoveryObservationContinuations.removeValue(forKey: identifier)
    }

    func publishRecoveryState(_ state: SwiftFulcrum.Client.ConnectionRecoveryObservation.State) {
        recoveryObservationState = state
        recoveryObservationSequence &+= 1
        let observation = recoveryObservation
        for continuation in recoveryObservationContinuations.values { continuation.yield(observation) }
    }

    func publishRecoveryReady(generation: UInt64) {
        guard connectionRecoveryGeneration == generation, !Task.isCancelled else { return }
        publishRecoveryState(.ready)
    }

    func observeRecoveryTransportState(_ observed: SwiftFulcrum.Client.ConnectionState) async {
        guard observed != .connected, observed != .connecting else { return }
        let generation = connectionRecoveryGeneration
        let current = await transport.connectionState
        // Raw transport streams can queue an old outage after a newer recovery completed.
        guard generation == connectionRecoveryGeneration, observed == current else { return }
        if recoveryObservationState == .ready { _ = advanceConnectionRecoveryGeneration() }
        let phase: SwiftFulcrum.Client.ConnectionRecoveryObservation.State = observed == .reconnecting ? .recovering : .unavailable
        if recoveryObservationState != phase { publishRecoveryState(phase) }
    }
}

extension FulcrumNetworkClient {
    struct SubscriptionResponse: Sendable {
        let data: Data
        let generation: UInt64
    }
}

private actor SubscriptionResponseIterator {
    private let nextResponse: () async throws -> FulcrumNetworkClient.SubscriptionResponse?
    private let onTermination: @Sendable () -> Void
    init(stream: AsyncThrowingStream<FulcrumNetworkClient.SubscriptionResponse, Swift.Error>, onTermination: @escaping @Sendable () -> Void) {
        var iterator = stream.makeAsyncIterator()
        nextResponse = { try await iterator.next() }
        self.onTermination = onTermination
    }
    func next() async throws -> FulcrumNetworkClient.SubscriptionResponse? { try await nextResponse() }
    deinit { onTermination() }
}

extension AsyncThrowingStream where Element == FulcrumNetworkClient.SubscriptionResponse, Failure == Swift.Error {
    func decode<Payload: Sendable>(using transform: @escaping @Sendable (Data, UInt64) throws -> Payload,
        onTermination: @escaping @Sendable () -> Void) -> AsyncThrowingStream<Payload, Swift.Error> {
        let iterator = SubscriptionResponseIterator(stream: self, onTermination: onTermination)
        return AsyncThrowingStream<Payload, Swift.Error> {
            guard let response = try await iterator.next() else { return nil }
            return try transform(response.data, response.generation)
        }
    }
}
