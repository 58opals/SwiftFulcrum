// Client~TestState.swift

import Foundation
@testable import SwiftFulcrum

extension SwiftFulcrum.Client {
    var startTaskGenerationIdentifierForTesting: UUID? {
        startTaskGenerationIdentifier
    }

    func makeStartTaskWaiterCountForTesting(
        generationIdentifier: UUID
    ) -> Int {
        startTaskWaiterCountsByGeneration[generationIdentifier, default: 0]
    }

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
