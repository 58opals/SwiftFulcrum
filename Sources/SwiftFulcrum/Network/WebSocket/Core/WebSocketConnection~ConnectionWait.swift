// WebSocketConnection~ConnectionWait.swift

import Foundation

extension WebSocketConnection {
    func makeOrReuseConnectTask(
        using attempt: ConnectionAttempt
    ) -> (identifier: UUID, task: Task<Void, Swift.Error>) {
        if let connectTask,
           !connectTask.isCancelled,
           let connectTaskGenerationIdentifier {
            return (connectTaskGenerationIdentifier, connectTask)
        }

        let precedingConnectTask = connectTask
        let generationIdentifier = UUID()
        let connection = self
        let connectTask = Task<Void, Swift.Error> {
            do {
                if let precedingConnectTask {
                    _ = await precedingConnectTask.result
                }
                try Task.checkCancellation()
                try await connection.performConnect(using: attempt)
                await connection.completeConnectTask(
                    generationIdentifier: generationIdentifier
                )
            } catch {
                await connection.completeConnectTask(
                    generationIdentifier: generationIdentifier
                )
                throw error
            }
        }
        self.connectTask = connectTask
        connectTaskGenerationIdentifier = generationIdentifier

        return (generationIdentifier, connectTask)
    }

    func waitForConnectTask(
        _ connectTask: Task<Void, Swift.Error>,
        generationIdentifier: UUID
    ) async throws {
        connectTaskWaiterCountsByGeneration[generationIdentifier, default: 0] += 1
        defer {
            let remainingWaiterCount =
                connectTaskWaiterCountsByGeneration[generationIdentifier, default: 1] - 1
            if remainingWaiterCount == 0 {
                connectTaskWaiterCountsByGeneration.removeValue(forKey: generationIdentifier)
            } else {
                connectTaskWaiterCountsByGeneration[generationIdentifier] = remainingWaiterCount
            }

            if Task.isCancelled, remainingWaiterCount == 0 {
                connectTask.cancel()
            }
        }

        try await connectTask.awaitCancellableValue(cancelUnderlyingTask: false)
    }

    func completeConnectTask(generationIdentifier: UUID) {
        guard connectTaskGenerationIdentifier == generationIdentifier else { return }
        connectTask = nil
        connectTaskGenerationIdentifier = nil
    }

    func waitForConnection(timeout: TimeInterval) async throws -> Bool {
        if await isConnected { return true }

        return try await waitForConnectionOnce(timeout: timeout)
    }

    private func waitForConnectionOnce(timeout: TimeInterval) async throws -> Bool {
        guard let task else {
            throw SwiftFulcrum.Client.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
        }

        return try await waitForConnectionOpenEvent(
            taskIdentifier: task.taskIdentifier,
            timeout: timeout,
            connectionEventTracker: connectionEventTracker
        )
    }

    private func waitForConnectionOpenEvent(
        taskIdentifier: Int,
        timeout: TimeInterval,
        connectionEventTracker: WebSocketConnectionEventTracker
    ) async throws -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await connectionEventTracker.waitForOpen(taskIdentifier: taskIdentifier)
                return true
            }

            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                return false
            }

            let winner = try await group.next() ?? false
            group.cancelAll()
            return winner
        }
    }

}
