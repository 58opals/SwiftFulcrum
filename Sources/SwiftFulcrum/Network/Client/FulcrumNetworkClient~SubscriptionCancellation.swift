// FulcrumNetworkClient~SubscriptionCancellation.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func awaitPendingSubscriptionCleanup(for key: SubscriptionKey) async {
        guard let task = subscriptionRegistry.cleanupTask(for: key) else { return }
        _ = await task.value
    }

    func awaitPendingSubscriptionCleanups() async {
        for task in subscriptionRegistry.makeCleanupTasks() {
            _ = await task.value
        }
    }
}

extension FulcrumNetworkClient {
    func recordSubscriptionCancellationRegistration(
        _ cancellationRegistration: SubscriptionCancellationRegistration?,
        for subscriptionKey: SubscriptionKey
    ) async {
        guard let cancellationRegistration else { return }

        if let existingRegistration = subscriptionRegistry.recordCancellationRegistration(
            cancellationRegistration,
            for: subscriptionKey
        ) {
            await existingRegistration.token.unregister(existingRegistration.registrationID)
        }
    }

    func clearSubscriptionCancellationRegistration(for subscriptionKey: SubscriptionKey) async {
        guard let cancellationRegistration = subscriptionRegistry.removeCancellationRegistration(for: subscriptionKey) else {
            return
        }

        await cancellationRegistration.token.unregister(cancellationRegistration.registrationID)
    }
}
