// Client~Lifecycle.swift

import Foundation

extension SwiftFulcrum.Client {
    func performStart() async throws {
        let observedStopGeneration = stopGeneration
        if let stopTask {
            try await stopTask.awaitCancellableValue(
                cancelUnderlyingTask: false
            )
        }
        guard stopGeneration == observedStopGeneration else { return }
        desiredRunning = true
        guard !isRunning else { return }

        let generation = makeOrReuseStartTask()
        do {
            try await waitForStartTask(
                generation.task,
                generationIdentifier: generation.identifier
            )
        } catch {
            if !(Task.isCancelled && error is CancellationError) {
                clearStartTaskIfCurrent(
                    generationIdentifier: generation.identifier
                )
            }
            if error is CancellationError,
               !desiredRunning
                || stopGeneration != observedStopGeneration {
                return
            }
            throw error
        }
        clearStartTaskIfCurrent(
            generationIdentifier: generation.identifier
        )

        guard desiredRunning,
              stopGeneration == observedStopGeneration else {
            return
        }
        markAsRunning()

        if connectionStateObservationTask == nil {
            startConnectionStateObservation()
        }
    }

    func makeOrReuseStartTask()
        -> (identifier: UUID, task: Task<Void, Swift.Error>) {
        if let startTask,
           !startTask.isCancelled,
           let startTaskGenerationIdentifier {
            return (startTaskGenerationIdentifier, startTask)
        }

        let generationIdentifier = UUID()
        let startTask = Task<Void, Swift.Error> { [client] in
            try await client.start()
        }
        self.startTask = startTask
        startTaskGenerationIdentifier = generationIdentifier
        return (generationIdentifier, startTask)
    }

    func waitForStartTask(
        _ startTask: Task<Void, Swift.Error>,
        generationIdentifier: UUID
    ) async throws {
        startTaskWaiterCountsByGeneration[
            generationIdentifier,
            default: 0
        ] += 1
        do {
            try await startTask.awaitCancellableValue(
                cancelUnderlyingTask: false
            )
            removeStartTaskWaiter(
                generationIdentifier: generationIdentifier
            )
        } catch {
            let remainingWaiterCount = removeStartTaskWaiter(
                generationIdentifier: generationIdentifier
            )
            if Task.isCancelled,
               error is CancellationError,
               remainingWaiterCount == 0 {
                startTask.cancel()
                clearStartTaskIfCurrent(
                    generationIdentifier: generationIdentifier
                )
            }
            throw error
        }
    }

    @discardableResult
    func removeStartTaskWaiter(
        generationIdentifier: UUID
    ) -> Int {
        let remainingWaiterCount =
            startTaskWaiterCountsByGeneration[
                generationIdentifier,
                default: 1
            ] - 1
        if remainingWaiterCount == 0 {
            startTaskWaiterCountsByGeneration.removeValue(
                forKey: generationIdentifier
            )
        } else {
            startTaskWaiterCountsByGeneration[generationIdentifier] =
                remainingWaiterCount
        }
        return remainingWaiterCount
    }

    func clearStartTaskIfCurrent(
        generationIdentifier: UUID
    ) {
        guard startTaskGenerationIdentifier == generationIdentifier else {
            return
        }
        startTask = nil
        startTaskGenerationIdentifier = nil
    }

    func performStop(inFlightStartTask: Task<Void, Swift.Error>?) async {
        let networkConnectionState = await client.connectionState
        let shouldPreserveIdleState =
            !isRunning &&
            inFlightStartTask == nil &&
            currentConnectionState == .idle &&
            networkConnectionState == .idle

        if shouldPreserveIdleState {
            await stopConnectionStateObservation()
        }

        await client.stop()
        if let inFlightStartTask {
            _ = try? await inFlightStartTask.value
        }
        desiredRunning = false

        if !shouldPreserveIdleState {
            await stopConnectionStateObservation()
        } else {
            currentConnectionState = .idle
        }
        await resetConnectionStateStream()

        stopTask = nil
    }
}
