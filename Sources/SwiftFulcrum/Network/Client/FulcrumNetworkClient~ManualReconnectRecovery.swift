// FulcrumNetworkClient~ManualReconnectRecovery.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func recoverManualReconnect(
        startingWith initialReconnectSuccessCount: Int,
        recoveryGeneration: UInt64,
        generationIdentifier: UUID
    ) async throws {
        var reconnectSuccessCount = initialReconnectSuccessCount

        while true {
            manualReconnectRecoverySuccessCount = reconnectSuccessCount
            resetNegotiatedSession()

            do {
                _ = try await ensureNegotiatedProtocol()
                OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                    event: .swiftFulcrumClientReconnectRecoveryBegin,
                    level: .info,
                    fields: await makeClientTransportDiagnosticFields()
                )
                try await resubscribeStoredMethods(
                    reconnectSuccessCount: reconnectSuccessCount,
                    recoveryGeneration: recoveryGeneration
                )
            } catch {
                let currentReconnectSuccessCount =
                    await transport.reconnectSuccesses
                guard currentReconnectSuccessCount != reconnectSuccessCount else {
                    throw error
                }
                reconnectSuccessCount = currentReconnectSuccessCount
                continue
            }

            let currentReconnectSuccessCount =
                await transport.reconnectSuccesses
            guard currentReconnectSuccessCount == reconnectSuccessCount else {
                reconnectSuccessCount = currentReconnectSuccessCount
                continue
            }

            OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                event: .swiftFulcrumClientReconnectRecoverySucceeded,
                level: .info,
                fields: await makeClientTransportDiagnosticFields([
                    .swiftFulcrumField(
                        "subscription_count",
                        subscriptionRegistry.count
                    )
                ])
            )

            recoveredReconnectSuccessCount = reconnectSuccessCount
            await recordClientState()
            let confirmedReconnectSuccessCount =
                await transport.reconnectSuccesses
            guard confirmedReconnectSuccessCount == reconnectSuccessCount else {
                reconnectSuccessCount = confirmedReconnectSuccessCount
                continue
            }

            clearAutomaticReconnectRecoveryNeed()
            if let pendingReconnectSuccessCount =
                finishOrTakePendingManualReconnectRecovery(
                    generationIdentifier: generationIdentifier
                ) {
                reconnectSuccessCount = pendingReconnectSuccessCount
                continue
            }
            return
        }
    }
}
