import Foundation

extension SwiftFulcrum.Client {
    /// Recovery phase stamped by the same producer generation as subscription observations.
    public struct ConnectionRecoveryObservation: Equatable, Sendable {
        public enum State: Equatable, Sendable { case unavailable, recovering, ready }
        public let generation: UInt64
        public let sequence: UInt64
        public let state: State
    }

    /// A payload stamped when it is published, rather than when an asynchronous consumer reads it.
    public struct SubscriptionObservation<Value: Sendable>: Sendable {
        public let value: Value
        public let generation: UInt64
    }

    /// Installs a listener and captures its current snapshot in one producer actor turn.
    /// Slow consumers do not delay recovery. Compare generations before applying data and
    /// sequences before applying phases; a delayed phase in an adopted generation must not
    /// invalidate data already hydrated in that generation. Ready means protocol recovery
    /// completed, not that downstream account data has been hydrated.
    public func makeConnectionRecoveryStream() async -> AsyncStream<ConnectionRecoveryObservation> {
        await client.makeConnectionRecoveryStream()
    }

    /// Starts one subscription with producer generation stamps and the existing cancellation
    /// and buffering contract. This is an alternative to subscribe, not a second listener for
    /// the same subscription key. The initial snapshot and every notification/restore are stamped.
    public func subscribeObserved<Initial: Decodable & Sendable, Update: Decodable & Sendable>(
        _ endpoint: SwiftFulcrum.API.Subscription<Initial, Update>,
        options: SwiftFulcrum.Client.Call.Options = .init()
    ) async throws -> Subscription<SubscriptionObservation<Initial>, SubscriptionObservation<Update>> {
        let observedStopGeneration = stopGeneration
        try await throwIfCancelled(options.cancellation?.token)
        let deadline = try makeDeadline(for: options.timeout)
        return try await makeSubscription(method: endpoint.method, options: options,
            deadline: deadline, observedStopGeneration: observedStopGeneration) { client, options in
                try await client.subscribeObserved(method: endpoint.method, options: options)
            }
    }
}
