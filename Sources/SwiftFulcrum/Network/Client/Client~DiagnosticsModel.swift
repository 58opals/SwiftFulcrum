// Client~DiagnosticsModel.swift

import Foundation

extension Client {
    func makeDiagnosticsSnapshot() async -> FulcrumClient.DiagnosticsModel.SnapshotModel {
        let transportSnapshot = await transport.makeDiagnosticsSnapshot()
        let inflightCount = await router.makeInflightUnaryCallCount()
        
        return .init(
            reconnectAttempts: transportSnapshot.reconnectAttempts,
            reconnectSuccesses: transportSnapshot.reconnectSuccesses,
            inflightUnaryCallCount: inflightCount,
            activeSubscriptionCount: subscriptionMethods.count
        )
    }
    
    func listSubscriptions() -> [FulcrumClient.DiagnosticsModel.SubscriptionModel] {
        subscriptionMethods.map { entry in
                .init(methodPath: entry.key.methodPath.rawValue, identifier: entry.key.identifier)
        }
    }
    
    func publishDiagnosticsSnapshot(inflightUnaryCallCount: Int? = nil) async {
        guard let metrics else { return }
        
        let transportSnapshot = await transport.makeDiagnosticsSnapshot()
        let inflightCount: Int
        if let inflightUnaryCallCount {
            inflightCount = inflightUnaryCallCount
        } else {
            inflightCount = await router.makeInflightUnaryCallCount()
        }
        let snapshot = FulcrumClient.DiagnosticsModel.SnapshotModel(
            reconnectAttempts: transportSnapshot.reconnectAttempts,
            reconnectSuccesses: transportSnapshot.reconnectSuccesses,
            inflightUnaryCallCount: inflightCount,
            activeSubscriptionCount: subscriptionMethods.count
        )
        
        await metrics.recordDiagnosticsUpdate(url: await transport.endpoint, snapshot: snapshot)
    }
    
    func publishSubscriptionRegistry() async {
        guard let metrics else { return }
        
        let subscriptions = listSubscriptions()
        await metrics.recordSubscriptionRegistryUpdate(url: await transport.endpoint, subscriptions: subscriptions)
    }
}
