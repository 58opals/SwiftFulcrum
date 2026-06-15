// FulcrumNetworkClient~SubscriptionIdentifiers.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func recordActiveSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        activeSubscriptionRequestIdentifiers[subscriptionKey] = requestIdentifier
    }

    func isCurrentActiveSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        activeSubscriptionRequestIdentifiers[subscriptionKey] == requestIdentifier
    }
}

extension FulcrumNetworkClient {
    func recordPendingSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        pendingSubscriptionRequestIdentifiers[subscriptionKey] = requestIdentifier
    }

    func isCurrentPendingSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        pendingSubscriptionRequestIdentifiers[subscriptionKey] == requestIdentifier
    }

    func clearPendingSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        guard pendingSubscriptionRequestIdentifiers[subscriptionKey] == requestIdentifier else { return }
        pendingSubscriptionRequestIdentifiers.removeValue(forKey: subscriptionKey)
    }
}

extension FulcrumNetworkClient {
    func recordSubscriptionSetupRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        subscriptionSetupRequestIdentifiers[subscriptionKey] = requestIdentifier
    }

    func isCurrentSubscriptionSetupRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        subscriptionSetupRequestIdentifiers[subscriptionKey] == requestIdentifier
    }

    func clearSubscriptionSetupRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        guard subscriptionSetupRequestIdentifiers[subscriptionKey] == requestIdentifier else { return }
        subscriptionSetupRequestIdentifiers.removeValue(forKey: subscriptionKey)
        subscriptionSetupTasks.removeValue(forKey: subscriptionKey)
    }

    @discardableResult
    func cancelCurrentSubscriptionSetupRequest(
        for subscriptionKey: SubscriptionKey,
        expectedRequestIdentifier: UUID? = nil,
        error: Swift.Error? = nil
    ) async -> Int? {
        guard let currentRequestIdentifier = subscriptionSetupRequestIdentifiers[subscriptionKey] else {
            return nil
        }
        if let expectedRequestIdentifier, currentRequestIdentifier != expectedRequestIdentifier {
            return nil
        }

        let setupTask = subscriptionSetupTasks.removeValue(forKey: subscriptionKey)
        subscriptionSetupRequestIdentifiers.removeValue(forKey: subscriptionKey)
        setupTask?.cancel()
        return await router.cancel(identifier: .uuid(currentRequestIdentifier), error: error)
    }
}
