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
        let removedSubscriptions = subscriptionRegistry.removeAllRecords()
        for task in removedSubscriptions.setupTasks {
            task.cancel()
        }

        for task in removedSubscriptions.cleanupTasks {
            task.cancel()
        }

        for cancellationRegistration in removedSubscriptions.cancellationRegistrations {
            await cancellationRegistration.token.unregister(cancellationRegistration.registrationID)
        }

        guard removedSubscriptions.didRemoveStoredSubscriptions else { return }
        await recordSubscriptionRegistry()
    }
}
