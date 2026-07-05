// FulcrumNetworkClient~SubscriptionIdentifiers.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func recordActiveSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        subscriptionRegistry.recordActive(requestIdentifier, for: subscriptionKey)
    }

    func isCurrentActiveSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        subscriptionRegistry.isCurrentRoutableRequest(requestIdentifier, for: subscriptionKey)
    }
}

extension FulcrumNetworkClient {
    func recordPendingSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        method: SwiftFulcrum.RPC.Method,
        for subscriptionKey: SubscriptionKey
    ) {
        subscriptionRegistry.recordPending(requestIdentifier, method: method, for: subscriptionKey)
    }

    func isCurrentPendingSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        subscriptionRegistry.isCurrentPendingRequest(requestIdentifier, for: subscriptionKey)
    }

    func clearPendingSubscriptionRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        subscriptionRegistry.clearPending(requestIdentifier, for: subscriptionKey)
    }
}

extension FulcrumNetworkClient {
    func recordSubscriptionSetupRequestIdentifier(
        _ requestIdentifier: UUID,
        task: Task<Void, Swift.Error>? = nil,
        for subscriptionKey: SubscriptionKey
    ) {
        subscriptionRegistry.recordSetup(requestIdentifier, task: task, for: subscriptionKey)
    }

    func isCurrentSubscriptionSetupRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) -> Bool {
        subscriptionRegistry.isCurrentSetupRequest(requestIdentifier, for: subscriptionKey)
    }

    func clearSubscriptionSetupRequestIdentifier(
        _ requestIdentifier: UUID,
        for subscriptionKey: SubscriptionKey
    ) {
        subscriptionRegistry.clearSetup(requestIdentifier, for: subscriptionKey)
    }

    @discardableResult
    func cancelCurrentSubscriptionSetupRequest(
        for subscriptionKey: SubscriptionKey,
        expectedRequestIdentifier: UUID? = nil,
        error: Swift.Error? = nil
    ) async -> Int? {
        guard let setup = subscriptionRegistry.cancelSetupRequest(
            for: subscriptionKey,
            expectedRequestIdentifier: expectedRequestIdentifier
        ) else {
            return nil
        }

        return await router.cancel(identifier: .uuid(setup.requestIdentifier), error: error)
    }
}
