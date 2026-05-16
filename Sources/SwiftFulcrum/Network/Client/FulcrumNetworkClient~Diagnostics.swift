// FulcrumNetworkClient~Diagnostics.swift

import Foundation

extension FulcrumNetworkClient {
    func makeDiagnosticsSnapshot() async -> SwiftFulcrum.Client.Diagnostics.Snapshot {
        await makeDiagnosticsSnapshot(inflightUnaryCallCount: nil)
    }

    func makeDiagnosticsSnapshot(
        inflightUnaryCallCount: Int?
    ) async -> SwiftFulcrum.Client.Diagnostics.Snapshot {
        let transportSnapshot = await transport.makeDiagnosticsSnapshot()
        let inflightCount = if let inflightUnaryCallCount {
            inflightUnaryCallCount
        } else {
            await router.makeInflightUnaryCallCount()
        }
        
        return .init(
            reconnectAttempts: transportSnapshot.reconnectAttempts,
            reconnectSuccesses: transportSnapshot.reconnectSuccesses,
            inflightUnaryCallCount: inflightCount,
            activeSubscriptionCount: subscriptionMethods.count
        )
    }
    
    func listSubscriptions() -> [SwiftFulcrum.Client.Diagnostics.Subscription] {
        subscriptionMethods.map { entry in
                .init(methodPath: entry.key.methodPath.rawValue, identifier: entry.key.identifier)
        }
    }
    
    func publishDiagnosticsSnapshot(inflightUnaryCallCount: Int? = nil) async {
        let snapshot = await makeDiagnosticsSnapshot(inflightUnaryCallCount: inflightUnaryCallCount)
        let endpoint = await transport.endpoint
        recordClientEvent(
            SwiftFulcrumDiagnostics.Event.clientDiagnosticsUpdated,
            fields: [
                SwiftFulcrumDiagnostics.endpointField(endpoint),
                SwiftFulcrumDiagnostics.publicField("reconnect_attempts", snapshot.reconnectAttempts),
                SwiftFulcrumDiagnostics.publicField("reconnect_successes", snapshot.reconnectSuccesses),
                SwiftFulcrumDiagnostics.publicField("inflight_unary_call_count", snapshot.inflightUnaryCallCount),
                SwiftFulcrumDiagnostics.publicField("active_subscription_count", snapshot.activeSubscriptionCount)
            ]
        )
    }
    
    func publishSubscriptionRegistry() async {
        let subscriptions = listSubscriptions()
        let endpoint = await transport.endpoint
        recordClientEvent(
            SwiftFulcrumDiagnostics.Event.clientSubscriptionsUpdated,
            fields: [
                SwiftFulcrumDiagnostics.endpointField(endpoint),
                SwiftFulcrumDiagnostics.publicField("subscription_count", subscriptions.count)
            ]
        )
    }
}
