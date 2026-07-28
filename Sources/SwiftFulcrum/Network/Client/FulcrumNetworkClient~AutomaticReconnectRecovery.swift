// FulcrumNetworkClient~AutomaticReconnectRecovery.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func prepareForAutomaticReconnectRecovery() {
        if let recoveryTask = reconnectRecoveryState.recoveryTask {
            recoveryTask.cancel()
            automaticReconnectRecoveryPredecessorTask = recoveryTask
        }
        automaticReconnectRecoverySuccessCount = nil
        automaticReconnectRecoveryGeneration = nil
        reconnectRecoveryTaskGenerationIdentifier = nil
        reconnectRecoveryState = .needed
    }

    func prepareForAutomaticReconnectRecoveryIfNeeded() async {
        guard reconnectTask == nil else { return }

        let observedConnectionGeneration = automaticReconnectConnectionGeneration
        let connectionState = await transport.connectionState
        guard automaticReconnectConnectionGeneration == observedConnectionGeneration,
              reconnectTask == nil,
              connectionState == .reconnecting else {
            return
        }
        guard reconnectRecoveryState.recoveryTask == nil else { return }
        prepareForAutomaticReconnectRecovery()
    }

    func beginAutomaticReconnectRecovery(
        reconnectSuccessCount: Int? = nil
    ) async -> Task<Void, Swift.Error>? {
        guard reconnectTask == nil else { return nil }
        let currentReconnectSuccessCount: Int
        if let reconnectSuccessCount {
            currentReconnectSuccessCount = reconnectSuccessCount
        } else {
            currentReconnectSuccessCount = await transport.reconnectSuccesses
        }
        guard reconnectTask == nil else { return nil }

        if currentReconnectSuccessCount > 0,
           currentReconnectSuccessCount <= recoveredReconnectSuccessCount {
            return nil
        }

        if let recoveryTask = reconnectRecoveryState.recoveryTask,
           automaticReconnectRecoverySuccessCount == currentReconnectSuccessCount {
            return recoveryTask
        }

        automaticReconnectConnectionGeneration &+= 1
        let recoveryGeneration = advanceConnectionRecoveryGeneration()
        prepareForAutomaticReconnectRecovery()
        automaticReconnectRecoverySuccessCount = currentReconnectSuccessCount
        automaticReconnectRecoveryGeneration = recoveryGeneration
        return makeOrReuseAutomaticReconnectRecoveryTask()
    }

    func makeOrReuseAutomaticReconnectRecoveryTask() -> Task<Void, Swift.Error> {
        if let recoveryTask = reconnectRecoveryState.recoveryTask,
           reconnectRecoveryTaskGenerationIdentifier != nil {
            return recoveryTask
        }

        let generationIdentifier = UUID()
        let predecessorTask = automaticReconnectRecoveryPredecessorTask
        let reconnectSuccessCount = automaticReconnectRecoverySuccessCount ?? 0
        let recoveryGeneration: UInt64
        if let automaticReconnectRecoveryGeneration {
            recoveryGeneration = automaticReconnectRecoveryGeneration
        } else {
            recoveryGeneration = advanceConnectionRecoveryGeneration()
            automaticReconnectRecoveryGeneration = recoveryGeneration
        }
        automaticReconnectRecoveryPredecessorTask = nil
        let owner = self
        let task = Task<Void, Swift.Error> {
            do {
                await owner.failInflightUnaryCallsForReconnect()
                if let predecessorTask {
                    _ = await predecessorTask.result
                }
                try Task.checkCancellation()
                try await owner.performAutomaticReconnectRecovery(
                    generationIdentifier: generationIdentifier,
                    reconnectSuccessCount: reconnectSuccessCount,
                    recoveryGeneration: recoveryGeneration
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                guard await owner.isCurrentAutomaticReconnectRecovery(
                    generationIdentifier: generationIdentifier,
                    recoveryGeneration: recoveryGeneration
                ) else {
                    throw CancellationError()
                }
                OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                    event: .swiftFulcrumClientReconnectRecoveryFailed,
                    level: .info,
                    fields: await owner.makeClientTransportDiagnosticFields(
                        OpalDiagnostics.Field.swiftFulcrumErrorFields(error)
                    )
                )
                await owner.handleAutomaticReconnectRecoveryFailure(
                    error,
                    generationIdentifier: generationIdentifier,
                    recoveryGeneration: recoveryGeneration
                )
                throw error
            }
        }
        reconnectRecoveryTaskGenerationIdentifier = generationIdentifier
        reconnectRecoveryState = .recovering(task)
        return task
    }

    func performAutomaticReconnectRecovery(
        generationIdentifier: UUID,
        reconnectSuccessCount: Int,
        recoveryGeneration: UInt64
    ) async throws {
        let connectionState = await transport.connectionState
        let currentReconnectSuccessCount = await transport.reconnectSuccesses
        guard connectionState == .connected,
              currentReconnectSuccessCount == reconnectSuccessCount,
              isCurrentAutomaticReconnectRecovery(
                  generationIdentifier: generationIdentifier,
                  recoveryGeneration: recoveryGeneration
              ) else {
            throw CancellationError()
        }
        resetNegotiatedSession()
        OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
            event: .swiftFulcrumClientReconnectRecoveryBegin,
            level: .info,
            fields: await makeClientTransportDiagnosticFields()
        )

        _ = try await ensureNegotiatedProtocol()
        try await resubscribeStoredMethods(
            reconnectSuccessCount: reconnectSuccessCount,
            recoveryGeneration: recoveryGeneration
        )
        let finalReconnectSuccessCount = await transport.reconnectSuccesses
        guard finalReconnectSuccessCount == reconnectSuccessCount,
              isCurrentAutomaticReconnectRecovery(
                  generationIdentifier: generationIdentifier,
                  recoveryGeneration: recoveryGeneration
              ) else {
            throw CancellationError()
        }
        recoveredReconnectSuccessCount = reconnectSuccessCount
        automaticReconnectRecoverySuccessCount = nil
        automaticReconnectRecoveryGeneration = nil
        reconnectRecoveryTaskGenerationIdentifier = nil
        reconnectRecoveryState = .idle
        OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
            event: .swiftFulcrumClientReconnectRecoverySucceeded,
            level: .info,
            fields: await makeClientTransportDiagnosticFields([
                .swiftFulcrumField("subscription_count", subscriptionRegistry.count)
            ])
        )
    }

    func handleAutomaticReconnectRecoveryFailure(
        _ error: Swift.Error,
        generationIdentifier: UUID,
        recoveryGeneration: UInt64
    ) async {
        guard isCurrentAutomaticReconnectRecovery(
            generationIdentifier: generationIdentifier,
            recoveryGeneration: recoveryGeneration
        ) else {
            return
        }
        automaticReconnectRecoverySuccessCount = nil
        automaticReconnectRecoveryGeneration = nil
        reconnectRecoveryTaskGenerationIdentifier = nil
        reconnectRecoveryState = .idle
        resetNegotiatedSession()

        let inflightCount = await router.failAll(with: error)
        await dropAllStoredSubscriptions()
        await recordClientState(inflightUnaryCallCount: inflightCount)
        await transport.disconnect(with: "FulcrumNetworkClient automatic reconnect recovery failed")
    }

}
