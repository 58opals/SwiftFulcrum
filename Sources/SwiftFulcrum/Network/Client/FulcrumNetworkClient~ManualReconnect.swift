// FulcrumNetworkClient~ManualReconnect.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func reconnect(with url: URL? = nil) async throws {
        let generation = makeOrReuseManualReconnectTask(with: url)
        try await waitForManualReconnectTask(
            generation.task,
            generationIdentifier: generation.identifier
        )
    }

    func makeOrReuseManualReconnectTask(
        with url: URL?
    ) -> (identifier: UUID, task: Task<Void, Swift.Error>) {
        if let reconnectTask,
           !reconnectTask.isCancelled,
           let reconnectTaskGenerationIdentifier {
            return (reconnectTaskGenerationIdentifier, reconnectTask)
        }

        let precedingReconnectTask = reconnectTask
        let generationIdentifier = UUID()
        pendingManualReconnectRecoverySuccessCount = nil
        let owner = self
        let reconnectTask = Task<Void, Swift.Error> {
            do {
                if let precedingReconnectTask {
                    _ = await precedingReconnectTask.result
                }
                try Task.checkCancellation()
                try await owner.performManualReconnect(
                    with: url,
                    generationIdentifier: generationIdentifier
                )
            } catch {
                await owner.completeManualReconnectTask(
                    generationIdentifier: generationIdentifier
                )
                throw error
            }
        }
        self.reconnectTask = reconnectTask
        reconnectTaskGenerationIdentifier = generationIdentifier
        return (generationIdentifier, reconnectTask)
    }

    func performManualReconnect(
        with url: URL?,
        generationIdentifier: UUID
    ) async throws {
        let recoveryGeneration = advanceConnectionRecoveryGeneration()
        await failInflightUnaryCallsForReconnect()
        await cancelBackgroundTasks()
        resetNegotiatedSession()
        startLifecycleObservationTasks()

        do {
            try await transport.reconnect(with: url)
            let reconnectSuccessCount = await transport.reconnectSuccesses
            manualReconnectRecoverySuccessCount = reconnectSuccessCount
            startReceivingTask()
            try await recoverManualReconnect(
                startingWith: reconnectSuccessCount,
                recoveryGeneration: recoveryGeneration,
                generationIdentifier: generationIdentifier
            )
        } catch {
            manualReconnectRecoverySuccessCount = nil
            await cancelBackgroundTasks()
            OpalDiagnostics.logger(category: .swiftFulcrumReconnect).record(
                event: .swiftFulcrumClientReconnectRecoveryFailed,
                level: .info,
                fields: await makeClientTransportDiagnosticFields(
                    OpalDiagnostics.Field.swiftFulcrumErrorFields(error)
                )
            )
            await transport.disconnect(with: "FulcrumNetworkClient.reconnect() failed")
            throw error
        }
    }

    func completeManualReconnectTask(generationIdentifier: UUID) {
        guard reconnectTaskGenerationIdentifier == generationIdentifier else { return }
        manualReconnectRecoverySuccessCount = nil
        pendingManualReconnectRecoverySuccessCount = nil
        reconnectTask = nil
        reconnectTaskGenerationIdentifier = nil
    }

    func finishOrTakePendingManualReconnectRecovery(
        generationIdentifier: UUID
    ) -> Int? {
        guard reconnectTaskGenerationIdentifier == generationIdentifier else {
            return nil
        }
        defer { pendingManualReconnectRecoverySuccessCount = nil }

        if let pendingManualReconnectRecoverySuccessCount,
           pendingManualReconnectRecoverySuccessCount
            > recoveredReconnectSuccessCount {
            return pendingManualReconnectRecoverySuccessCount
        }

        completeManualReconnectTask(
            generationIdentifier: generationIdentifier
        )
        return nil
    }

    private func waitForManualReconnectTask(
        _ reconnectTask: Task<Void, Swift.Error>,
        generationIdentifier: UUID
    ) async throws {
        reconnectTaskWaiterCountsByGeneration[generationIdentifier, default: 0] += 1
        do {
            try await reconnectTask.awaitCancellableValue(cancelUnderlyingTask: false)
            removeManualReconnectWaiter(generationIdentifier: generationIdentifier)
        } catch {
            let remainingWaiterCount = removeManualReconnectWaiter(
                generationIdentifier: generationIdentifier
            )
            if Task.isCancelled,
               error is CancellationError,
               remainingWaiterCount == 0 {
                reconnectTask.cancel()
                _ = try? await reconnectTask.value
                throw CancellationError()
            }
            throw error
        }
    }

    @discardableResult
    private func removeManualReconnectWaiter(
        generationIdentifier: UUID
    ) -> Int {
        let remainingWaiterCount =
            reconnectTaskWaiterCountsByGeneration[generationIdentifier, default: 1] - 1
        if remainingWaiterCount == 0 {
            reconnectTaskWaiterCountsByGeneration.removeValue(
                forKey: generationIdentifier
            )
        } else {
            reconnectTaskWaiterCountsByGeneration[generationIdentifier] =
                remainingWaiterCount
        }
        return remainingWaiterCount
    }
}
