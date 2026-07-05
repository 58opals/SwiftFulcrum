// FulcrumNetworkClient~SubscriptionCleanup.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func scheduleSubscriptionCleanup(
        for subscriptionKey: SubscriptionKey,
        requestIdentifier: UUID,
        reason: SubscriptionCleanupReason = .streamTermination(nil),
        sendUnsubscribe: Bool = false,
        scope: SubscriptionCleanupScope = .request
    ) async -> Bool {
        if let task = subscriptionRegistry.cleanupTask(for: subscriptionKey) {
            return await task.value
        }

        let owner = self
        let task = Task<Bool, Never> {

            let didRemove = await owner.cleanUpSubscriptionSetup(
                for: subscriptionKey,
                requestIdentifier: requestIdentifier,
                reason: reason,
                scope: scope
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

        subscriptionRegistry.recordCleanupTask(task, for: subscriptionKey)
        let didRemove = await task.value
        subscriptionRegistry.removeCleanupTask(for: subscriptionKey)
        return didRemove
    }
}

extension FulcrumNetworkClient {
    func shouldSendDeferredUnsubscribe(for subscriptionKey: SubscriptionKey) -> Bool {
        subscriptionRegistry.shouldSendDeferredUnsubscribe(for: subscriptionKey)
    }
}

extension FulcrumNetworkClient {
    @discardableResult
    func removeStoredSubscriptionMethod(
        for key: SubscriptionKey,
        requestIdentifier: UUID,
        scope: SubscriptionCleanupScope
    ) async -> Bool {
        subscriptionRegistry.removeRecord(
            for: key,
            requestIdentifier: requestIdentifier,
            requiringRoutableRequest: scope.requiresActiveRequestIdentifier
        ) != nil
    }

    @discardableResult
    func cleanUpSubscriptionSetup(for subscriptionKey: SubscriptionKey,
                                  requestIdentifier: UUID,
                                  reason: SubscriptionCleanupReason = .streamTermination(nil),
                                  scope: SubscriptionCleanupScope = .request) async -> Bool {
        let error = reason.error
        let isCurrentSubscriptionRequest = subscriptionRegistry.isCurrentRequest(
            requestIdentifier,
            for: subscriptionKey
        )
        let isCurrentOriginRequest = subscriptionRegistry.isCurrentOriginRequest(
            requestIdentifier,
            for: subscriptionKey
        )
        let setupInflightCount: Int?
        if isCurrentOriginRequest && !isCurrentSubscriptionRequest {
            setupInflightCount = await cancelCurrentSubscriptionSetupRequest(
                for: subscriptionKey,
                error: error
            )
        } else {
            setupInflightCount = await cancelCurrentSubscriptionSetupRequest(
                for: subscriptionKey,
                expectedRequestIdentifier: requestIdentifier,
                error: error
            )
        }
        let inflightCount: Int?
        if let setupInflightCount {
            inflightCount = setupInflightCount
        } else {
            inflightCount = await router.cancel(
                identifier: .uuid(requestIdentifier),
                error: error
            )
        }
        let shouldRemoveCurrentSubscription = subscriptionRegistry.acceptsCleanupRequest(
            requestIdentifier,
            for: subscriptionKey,
            requiringRoutableRequest: scope.requiresActiveRequestIdentifier
        )

        if shouldRemoveCurrentSubscription {
            await router.cancel(identifier: .string(subscriptionKey.string), error: error)
            await clearSubscriptionCancellationRegistration(for: subscriptionKey)
        }

        let didRemove = await removeStoredSubscriptionMethod(
            for: subscriptionKey,
            requestIdentifier: requestIdentifier,
            scope: scope
        )

        if didRemove {
            OpalDiagnostics.logger(category: .fulcrum).record(
                event: .swiftFulcrumClientSubscriptionRemoved,
                level: .info,
                traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestIdentifier),
                fields: makeClientDiagnosticFields([
                    .swiftFulcrumPrivateField("subscription_identifier", subscriptionKey.identifier ?? ""),
                    .swiftFulcrumField("method_path", subscriptionKey.methodPath.rawValue),
                    .swiftFulcrumField("subscription_count", subscriptionRegistry.count)
                ])
            )
            await recordSubscriptionRegistry()
        }

        await recordClientState(inflightUnaryCallCount: inflightCount)

        return didRemove
    }
}
