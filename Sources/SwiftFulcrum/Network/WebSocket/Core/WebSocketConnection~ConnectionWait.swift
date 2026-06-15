// WebSocketConnection~ConnectionWait.swift

import Foundation

extension WebSocketConnection {
    func finishConnectTaskWaiters(_ result: Result<Void, Error>) {
        let waiters = connectTaskWaitersByIdentifier.values
        connectTaskWaitersByIdentifier.removeAll(keepingCapacity: false)
        for continuation in waiters {
            continuation.resume(with: result)
        }
    }

    func cancelConnectTaskWaiter(identifier: UUID) {
        guard let continuation = connectTaskWaitersByIdentifier.removeValue(forKey: identifier) else { return }
        continuation.resume(throwing: CancellationError())
    }

    func waitForActiveConnectTask() async throws {
        let waiterIdentifier = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                connectTaskWaitersByIdentifier[waiterIdentifier] = continuation
            }
        } onCancel: {
            Task {
                await self.cancelConnectTaskWaiter(identifier: waiterIdentifier)
            }
        }
    }

    func finishConnectWaiters(_ result: Result<Bool, Error>) {
        let waiters = connectWaitersByIdentifier.values
        connectWaitersByIdentifier.removeAll(keepingCapacity: false)
        isConnectionInFlight = false
        for continuation in waiters {
            switch result {
            case .success(let isSuccessful): continuation.resume(returning: isSuccessful)
            case .failure(let error): continuation.resume(throwing: error)
            }
        }
    }

    func cancelConnectWaiter(identifier: UUID) {
        guard let continuation = connectWaitersByIdentifier.removeValue(forKey: identifier) else { return }
        continuation.resume(throwing: CancellationError())
    }

    func waitForConnection(timeout: TimeInterval) async throws -> Bool {
        if await isConnected { return true }

        if isConnectionInFlight {
            let waiterIdentifier = UUID()
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    connectWaitersByIdentifier[waiterIdentifier] = continuation
                }
            } onCancel: {
                Task {
                    await self.cancelConnectWaiter(identifier: waiterIdentifier)
                }
            }
        }

        isConnectionInFlight = true
        do {
            let isSuccessful = try await waitForConnectionOnce(timeout: timeout)
            finishConnectWaiters(.success(isSuccessful))
            return isSuccessful
        } catch {
            finishConnectWaiters(.failure(error))
            throw error
        }
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
