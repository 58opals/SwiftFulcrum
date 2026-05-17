// Client~TestState.swift

@testable import SwiftFulcrum

extension SwiftFulcrum.Client {
    func makeActiveSubscriptionStates() async -> [ClientSubscriptionState] {
        await client.makeActiveSubscriptionStates()
    }

    func makeActiveSubscriptionCount() async -> Int {
        await makeActiveSubscriptionStates().count
    }

    func makeInflightUnaryCallCount() async -> Int {
        await client.makeInflightUnaryCallCount()
    }
}
