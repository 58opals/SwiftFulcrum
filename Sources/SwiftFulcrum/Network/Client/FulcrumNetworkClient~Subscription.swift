// FulcrumNetworkClient~Subscription.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    struct SubscriptionCancellationRegistration: Sendable {
        let token: FulcrumNetworkClient.Call.Token
        let registrationID: FulcrumNetworkClient.Call.Token.RegistrationID
    }
}

extension FulcrumNetworkClient {
    func dropAllStoredSubscriptions() async {
        let setupTasks = Array(subscriptionSetupTasks.values)
        pendingSubscriptionRequestIdentifiers.removeAll(keepingCapacity: false)
        subscriptionSetupRequestIdentifiers.removeAll(keepingCapacity: false)
        subscriptionSetupTasks.removeAll(keepingCapacity: false)
        for task in setupTasks {
            task.cancel()
        }

        let cleanupTasks = Array(subscriptionCleanupTasks.values)
        subscriptionCleanupTasks.removeAll(keepingCapacity: false)
        for task in cleanupTasks {
            task.cancel()
        }

        let cancellationRegistrations = Array(subscriptionCancellationRegistrations.values)
        subscriptionCancellationRegistrations.removeAll(keepingCapacity: false)
        for cancellationRegistration in cancellationRegistrations {
            await cancellationRegistration.token.unregister(cancellationRegistration.registrationID)
        }

        guard !subscriptionMethods.isEmpty else { return }
        subscriptionMethods.removeAll(keepingCapacity: false)
        activeSubscriptionRequestIdentifiers.removeAll(keepingCapacity: false)
        await recordSubscriptionRegistry()
    }
}
