// FulcrumNetworkClient~SubscriptionCancellation.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func awaitPendingSubscriptionCleanup(for key: SubscriptionKey) async {
        guard let task = subscriptionCleanupTasks[key] else { return }
        _ = await task.value
    }

    func awaitPendingSubscriptionCleanups() async {
        let tasks = Array(subscriptionCleanupTasks.values)
        for task in tasks {
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

        if let existingRegistration = subscriptionCancellationRegistrations.updateValue(
            cancellationRegistration,
            forKey: subscriptionKey
        ) {
            await existingRegistration.token.unregister(existingRegistration.registrationID)
        }
    }

    func clearSubscriptionCancellationRegistration(for subscriptionKey: SubscriptionKey) async {
        guard let cancellationRegistration = subscriptionCancellationRegistrations.removeValue(forKey: subscriptionKey) else {
            return
        }

        await cancellationRegistration.token.unregister(cancellationRegistration.registrationID)
    }
}
