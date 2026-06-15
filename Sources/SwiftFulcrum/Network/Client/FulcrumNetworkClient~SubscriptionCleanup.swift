// FulcrumNetworkClient~SubscriptionCleanup.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func scheduleSubscriptionCleanup(
        for subscriptionKey: SubscriptionKey,
        requestIdentifier: UUID,
        error: Swift.Error? = nil,
        sendUnsubscribe: Bool = false,
        preferCurrentSetupRequest: Bool = false,
        requireMatchingActiveRequestIdentifier: Bool = false
    ) async -> Bool {
        if let task = subscriptionCleanupTasks[subscriptionKey] {
            return await task.value
        }

        let owner = self
        let task = Task<Bool, Never> {

            let didRemove = await owner.cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: requestIdentifier,
                error: error,
                preferCurrentSetupRequest: preferCurrentSetupRequest,
                requireMatchingActiveRequestIdentifier: requireMatchingActiveRequestIdentifier
            )

            guard sendUnsubscribe,
                  didRemove,
                  let method = await owner.makeUnsubscribeMethod(for: subscriptionKey) else {
                return didRemove
            }

            let request = method.createRequest(with: UUID())
            guard let requestData = request.data else {
                return didRemove
            }

            await Task.yield()
            guard await owner.shouldSendDeferredUnsubscribe(for: subscriptionKey) else {
                return didRemove
            }

            try? await owner.send(data: requestData)
            return didRemove
        }

        subscriptionCleanupTasks[subscriptionKey] = task
        let didRemove = await task.value
        subscriptionCleanupTasks.removeValue(forKey: subscriptionKey)
        return didRemove
    }
}

extension FulcrumNetworkClient {
    func shouldSendDeferredUnsubscribe(for subscriptionKey: SubscriptionKey) -> Bool {
        pendingSubscriptionRequestIdentifiers[subscriptionKey] == nil
            && subscriptionSetupRequestIdentifiers[subscriptionKey] == nil
            && activeSubscriptionRequestIdentifiers[subscriptionKey] == nil
            && subscriptionMethods[subscriptionKey] == nil
    }
}

extension FulcrumNetworkClient {
    @discardableResult
    func removeStoredSubscriptionMethod(
        for key: SubscriptionKey,
        requestIdentifier: UUID,
        requireMatchingActiveRequestIdentifier: Bool
    ) async -> Bool {
        if requireMatchingActiveRequestIdentifier,
           activeSubscriptionRequestIdentifiers[key] != requestIdentifier {
            return false
        }
        activeSubscriptionRequestIdentifiers.removeValue(forKey: key)
        guard subscriptionMethods.removeValue(forKey: key) != nil else { return false }
        return true
    }

    @discardableResult
    func cleanUpSubscriptionSetup(for subscriptionKey: SubscriptionKey,
                                  requestIdentifier: UUID,
                                  error: Swift.Error? = nil,
                                  preferCurrentSetupRequest: Bool = false,
                                  requireMatchingActiveRequestIdentifier: Bool = false) async -> Bool {
        let inflightCount: Int?
        if preferCurrentSetupRequest {
            if let currentInflightCount = await cancelCurrentSubscriptionSetupRequest(
                for: subscriptionKey,
                error: error
            ) {
                inflightCount = currentInflightCount
            } else if let expectedInflightCount = await cancelCurrentSubscriptionSetupRequest(
                for: subscriptionKey,
                expectedRequestIdentifier: requestIdentifier,
                error: error
            ) {
                inflightCount = expectedInflightCount
            } else {
                inflightCount = await router.cancel(identifier: .uuid(requestIdentifier), error: error)
            }
        } else {
            if let expectedInflightCount = await cancelCurrentSubscriptionSetupRequest(
                for: subscriptionKey,
                expectedRequestIdentifier: requestIdentifier,
                error: error
            ) {
                inflightCount = expectedInflightCount
            } else {
                inflightCount = await router.cancel(identifier: .uuid(requestIdentifier), error: error)
            }
        }
        let isCurrentActiveSubscription = isCurrentActiveSubscriptionRequestIdentifier(
            requestIdentifier,
            for: subscriptionKey
        )

        let shouldRemoveCurrentSubscription = !requireMatchingActiveRequestIdentifier || isCurrentActiveSubscription

        if shouldRemoveCurrentSubscription {
            await router.cancel(identifier: .string(subscriptionKey.string), error: error)
            await clearSubscriptionCancellationRegistration(for: subscriptionKey)
        }

        let didRemove = await removeStoredSubscriptionMethod(
            for: subscriptionKey,
            requestIdentifier: requestIdentifier,
            requireMatchingActiveRequestIdentifier: requireMatchingActiveRequestIdentifier
        )

        if didRemove {
            OpalDiagnostics.logger(category: .fulcrum).record(
                event: .swiftFulcrumClientSubscriptionRemoved,
                level: .info,
                traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestIdentifier),
                fields: makeClientDiagnosticFields([
                    .swiftFulcrumPrivateField("subscription_identifier", subscriptionKey.identifier ?? ""),
                    .swiftFulcrumField("method_path", subscriptionKey.methodPath.rawValue),
                    .swiftFulcrumField("subscription_count", subscriptionMethods.count)
                ])
            )
            await recordSubscriptionRegistry()
        }

        await recordClientState(inflightUnaryCallCount: inflightCount)

        return didRemove
    }
}
