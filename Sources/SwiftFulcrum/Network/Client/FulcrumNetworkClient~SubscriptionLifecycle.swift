// FulcrumNetworkClient~SubscriptionLifecycle.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func configureSubscriptionLifecycle(
        rawContinuation: AsyncThrowingStream<Data, Swift.Error>.Continuation,
        subscriptionKey: SubscriptionKey,
        method: SwiftFulcrum.RPC.Method,
        requestIdentifier: UUID,
        subscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy
    ) async throws {
        await awaitPendingSubscriptionCleanup(for: subscriptionKey)
        try Task.checkCancellation()
        guard subscriptionRegistry.method(for: subscriptionKey) == nil else {
            throw SwiftFulcrum.Client.Error.client(.duplicateRegistration)
        }

        recordPendingSubscriptionRequestIdentifier(requestIdentifier, method: method, for: subscriptionKey)
        defer {
            clearPendingSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey)
        }

        guard isCurrentPendingSubscriptionRequestIdentifier(requestIdentifier, for: subscriptionKey) else {
            throw CancellationError()
        }
        recordSubscriptionSetupRequestIdentifier(requestIdentifier, for: subscriptionKey)
        try await router.addStream(
            key: subscriptionKey.string,
            continuation: rawContinuation,
            overflowError: subscriptionBufferPolicy.overflowError,
            terminationAction: { [weak self] error in
                guard let self else { return }
                _ = await self.scheduleSubscriptionCleanup(
                    for: subscriptionKey,
                    requestIdentifier: requestIdentifier,
                    reason: error.map { .overflow($0) } ?? .streamTermination(nil),
                    sendUnsubscribe: true,
                    scope: .currentSetupThenActiveRequest
                )
            }
        )

        OpalDiagnostics.logger(category: .fulcrum).record(
            event: .swiftFulcrumClientSubscriptionAdded,
            level: .info,
            traceID: OpalDiagnostics.TraceID(swiftFulcrumRequestID: requestIdentifier),
            fields: makeClientDiagnosticFields([
                .swiftFulcrumPrivateField("subscription_identifier", subscriptionKey.identifier ?? ""),
                .swiftFulcrumMethodPath(method.path),
                .swiftFulcrumField("subscription_count", subscriptionRegistry.count)
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
                        reason: .streamTermination(nil),
                        sendUnsubscribe: true,
                        scope: .currentSetupThenActiveRequest
                )
            }
        }
    }
}
