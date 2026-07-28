// FulcrumNetworkClient~Startup.swift

import Foundation

extension FulcrumNetworkClient {
    func start() async throws {
        let generation = makeOrReuseStartupTask()
        try await waitForStartupTask(
            generation.task,
            generationIdentifier: generation.identifier
        )
    }
}

private extension FulcrumNetworkClient {
    func performStart() async throws {
        guard receiveTask == nil else { return }
        resetNegotiatedSession()

        try await transport.connect()
        let connectedReconnectSuccessCount = await transport.reconnectSuccesses
        startReceivingTask()
        startLifecycleObservationTasks()

        do {
            _ = try await ensureNegotiatedProtocol()
            let currentReconnectSuccessCount =
                await transport.reconnectSuccesses
            if currentReconnectSuccessCount == connectedReconnectSuccessCount {
                recoveredReconnectSuccessCount = currentReconnectSuccessCount
            } else {
                try await awaitReconnectReadiness()
            }

            startRPCHeartbeat()
            await recordClientState()
        } catch {
            await cancelBackgroundTasks()
            await transport.disconnect(
                with: "FulcrumNetworkClient.start() negotiation failed"
            )
            throw error
        }
    }

    func makeOrReuseStartupTask()
        -> (identifier: UUID, task: Task<Void, Swift.Error>) {
        if let startupTask,
           !startupTask.isCancelled,
           let startupTaskGenerationIdentifier {
            return (startupTaskGenerationIdentifier, startupTask)
        }

        let precedingStartupTask = startupTask
        let generationIdentifier = UUID()
        let owner = self
        let startupTask = Task<Void, Swift.Error> {
            do {
                if let precedingStartupTask {
                    _ = await precedingStartupTask.result
                }
                try Task.checkCancellation()
                try await owner.performStart()
                await owner.completeStartupTask(
                    generationIdentifier: generationIdentifier
                )
            } catch {
                await owner.completeStartupTask(
                    generationIdentifier: generationIdentifier
                )
                throw error
            }
        }
        self.startupTask = startupTask
        startupTaskGenerationIdentifier = generationIdentifier
        return (generationIdentifier, startupTask)
    }

    func waitForStartupTask(
        _ startupTask: Task<Void, Swift.Error>,
        generationIdentifier: UUID
    ) async throws {
        startupTaskWaiterCountsByGeneration[
            generationIdentifier,
            default: 0
        ] += 1
        defer {
            let remainingWaiterCount =
                startupTaskWaiterCountsByGeneration[
                    generationIdentifier,
                    default: 1
                ] - 1
            if remainingWaiterCount == 0 {
                startupTaskWaiterCountsByGeneration.removeValue(
                    forKey: generationIdentifier
                )
            } else {
                startupTaskWaiterCountsByGeneration[generationIdentifier] =
                    remainingWaiterCount
            }

            if Task.isCancelled, remainingWaiterCount == 0 {
                startupTask.cancel()
            }
        }

        try await startupTask.awaitCancellableValue(
            cancelUnderlyingTask: false
        )
    }

    func completeStartupTask(generationIdentifier: UUID) {
        guard startupTaskGenerationIdentifier
                == generationIdentifier else {
            return
        }
        startupTask = nil
        startupTaskGenerationIdentifier = nil
    }
}
