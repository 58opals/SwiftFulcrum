// FulcrumNetworkClient~SubscriptionCancellation.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func shouldSendUnsubscribeOnCancellation(
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        subscriptionRegistry.shouldSendUnsubscribeOnCancellation(
            for: subscriptionKey
        )
    }

    func awaitPendingSubscriptionCleanup(for key: SubscriptionKey) async throws {
        guard let task = subscriptionRegistry.cleanupTask(for: key) else { return }
        _ = try await task.awaitCancellableValue(cancelUnderlyingTask: false)
    }

    func awaitPendingSubscriptionCleanups() async throws {
        for task in subscriptionRegistry.makeCleanupTasks() {
            _ = try await task.awaitCancellableValue(cancelUnderlyingTask: false)
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
