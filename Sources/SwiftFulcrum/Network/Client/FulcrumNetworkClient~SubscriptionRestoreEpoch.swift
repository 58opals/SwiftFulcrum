// FulcrumNetworkClient~SubscriptionRestoreEpoch.swift

import Foundation

extension FulcrumNetworkClient {
    func isSubscriptionRestoreCurrent(_ restore: SubscriptionRestoreContext) async -> Bool {
        guard isCurrentSubscriptionSetupRequestIdentifier(
            restore.requestIdentifier,
            for: restore.subscriptionKey
        ) else { return false }
        let reconnectSuccessCount = await transport.reconnectSuccesses
        return connectionRecoveryGeneration == restore.recoveryGeneration
            && reconnectSuccessCount == restore.reconnectSuccessCount
            && isCurrentSubscriptionSetupRequestIdentifier(
                restore.requestIdentifier,
                for: restore.subscriptionKey
            )
    }

    func ensureSubscriptionRestoreIsCurrent(
        reconnectSuccessCount: Int,
        recoveryGeneration: UInt64
    ) async throws {
        guard connectionRecoveryGeneration == recoveryGeneration,
              await transport.reconnectSuccesses == reconnectSuccessCount else {
            throw CancellationError()
        }
    }

    func isSubscriptionRestoreSuperseded(
        reconnectSuccessCount: Int,
        recoveryGeneration: UInt64
    ) async -> Bool {
        guard connectionRecoveryGeneration == recoveryGeneration else {
            return true
        }
        return await transport.reconnectSuccesses != reconnectSuccessCount
    }

    func preserveStoredSubscriptionAfterSupersededRestore(
        for subscriptionKey: SubscriptionKey,
        requestIdentifier: UUID
    ) async {
        let setupInflightCount = await cancelCurrentSubscriptionSetupRequest(
            for: subscriptionKey,
            expectedRequestIdentifier: requestIdentifier,
            error: CancellationError()
        )
        let inflightCount: Int?
        if let setupInflightCount {
            inflightCount = setupInflightCount
        } else {
            inflightCount = await router.cancel(
                identifier: .uuid(requestIdentifier),
                error: CancellationError()
            )
        }
        await recordClientState(inflightUnaryCallCount: inflightCount)
    }
}
