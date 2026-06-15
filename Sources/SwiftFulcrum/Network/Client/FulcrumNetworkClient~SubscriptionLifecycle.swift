// FulcrumNetworkClient~SubscriptionLifecycle.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func configureSubscriptionLifecycle(
        rawContinuation: AsyncThrowingStream<Data, Swift.Error>.Continuation,
        subscriptionKey: SubscriptionKey,
        method: SwiftFulcrum.RPC.Method,
        requestIdentifier: UUID
    ) async throws {
        recordPendingSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey)
        defer {
            clearPendingSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey)
        }

        await awaitPendingSubscriptionCleanup(for: subscriptionKey)
        try Task.checkCancellation()
        guard isCurrentPendingSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey) else {
            throw CancellationError()
        }
        recordSubscriptionSetupRequestIdentifier(requestIdentifier, for: subscriptionKey)
        try await router.addStream(
            key: subscriptionKey.string,
            continuation: rawContinuation
        )
        recordActiveSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey)
        subscriptionMethods[subscriptionKey] = method

        OpalDiagnostics.logger(category: .fulcrum).record(
            event: .swiftFulcrumClientSubscriptionAdded,
            level: .info,
            traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestIdentifier),
            fields: makeClientDiagnosticFields([
                .swiftFulcrumPrivateField("subscription_identifier", subscriptionKey.identifier ?? ""),
                .swiftFulcrumMethodPath(method.path),
                .swiftFulcrumField("subscription_count", subscriptionMethods.count)
            ])
        )
        await recordSubscriptionRegistry()
        await recordClientState()

        rawContinuation.onTermination = { @Sendable [weak self] _ in
            guard let self else { return }

            Task {
                _ = await self.scheduleSubscriptionCleanup(
                    for: subscriptionKey,
                    requestIdentifier: requestIdentifier,
                    sendUnsubscribe: true,
                    preferCurrentSetupRequest: true,
                    requireMatchingActiveRequestIdentifier: true
                )
            }
        }
    }
}
