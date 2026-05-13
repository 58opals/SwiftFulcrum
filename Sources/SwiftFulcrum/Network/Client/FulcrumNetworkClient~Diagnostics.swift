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
        guard let metrics else { return }
        
        let snapshot = await makeDiagnosticsSnapshot(inflightUnaryCallCount: inflightUnaryCallCount)
        await metrics.recordDiagnosticsUpdate(url: await transport.endpoint, snapshot: snapshot)
    }
    
    func publishSubscriptionRegistry() async {
        guard let metrics else { return }
        
        let subscriptions = listSubscriptions()
        await metrics.recordSubscriptionRegistryUpdate(url: await transport.endpoint, subscriptions: subscriptions)
    }
}
