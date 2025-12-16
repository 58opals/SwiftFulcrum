// Client~Diagnostics.swift

import Foundation

extension Client {
    func makeDiagnosticsSnapshot() async -> Fulcrum.Diagnostics.Snapshot {
        let transportSnapshot = await transport.makeDiagnosticsSnapshot()
        let inflightCount = await router.makeInflightUnaryCallCount()
        
        return .init(
            reconnectAttempts: transportSnapshot.reconnectAttempts,
            reconnectSuccesses: transportSnapshot.reconnectSuccesses,
            inflightUnaryCallCount: inflightCount,
            activeSubscriptionCount: subscriptionMethods.count
        )
    }
    
    func listSubscriptions() -> [Fulcrum.Diagnostics.Subscription] {
        subscriptionMethods.map { entry in
                .init(methodPath: entry.key.methodPath, identifier: entry.key.identifier)
        }
    }
    
    func publishDiagnosticsSnapshot(inflightUnaryCallCount: Int? = nil) async {
        guard let metrics else { return }
        
        let transportSnapshot = await transport.makeDiagnosticsSnapshot()
        let inflightCount = inflightUnaryCallCount ?? await router.makeInflightUnaryCallCount()
        let snapshot = Fulcrum.Diagnostics.Snapshot(
            reconnectAttempts: transportSnapshot.reconnectAttempts,
            reconnectSuccesses: transportSnapshot.reconnectSuccesses,
            inflightUnaryCallCount: inflightCount,
            activeSubscriptionCount: subscriptionMethods.count
        )
        
        await metrics.didUpdateDiagnostics(url: await transport.endpoint, snapshot: snapshot)
    }
    
    func publishSubscriptionRegistry() async {
        guard let metrics else { return }
        
        let subscriptions = listSubscriptions()
        await metrics.didUpdateSubscriptionRegistry(url: await transport.endpoint, subscriptions: subscriptions)
    }
}
