// FulcrumNetworkClient~TestState.swift

@testable import SwiftFulcrum

extension FulcrumNetworkClient {
    func makeActiveSubscriptionStates() -> [ClientSubscriptionState] {
        subscriptionRegistry.makeRecords().map { entry in
            ClientSubscriptionState(
                methodPath: entry.key.methodPath.rawValue,
                identifier: entry.key.identifier,
                phase: String(describing: entry.value.phase)
            )
        }
    }

    func makeInflightUnaryCallCount() async -> Int {
        await router.makeInflightUnaryCallCount()
    }
}
