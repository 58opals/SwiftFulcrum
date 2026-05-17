// FulcrumNetworkClient~TestState.swift

@testable import SwiftFulcrum

extension FulcrumNetworkClient {
    func makeActiveSubscriptionStates() -> [ClientSubscriptionState] {
        subscriptionMethods.map { entry in
            ClientSubscriptionState(
                methodPath: entry.key.methodPath.rawValue,
                identifier: entry.key.identifier
            )
        }
    }

    func makeInflightUnaryCallCount() async -> Int {
        await router.makeInflightUnaryCallCount()
    }
}
