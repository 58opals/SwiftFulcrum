// FulcrumNetworkClient~TestState.swift

@testable import SwiftFulcrum

extension FulcrumNetworkClient {
    var isRPCHeartbeatStoppedForTesting: Bool {
        rpcHeartbeatTask == nil
    }

    var isReceiveTaskStoppedForTesting: Bool {
        receiveTask == nil
    }

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

    func recordSubscriptionCleanupTask(
        _ task: Task<Bool, Never>,
        for key: SubscriptionKey
    ) {
        subscriptionRegistry.recordCleanupTask(task, for: key)
    }
}
