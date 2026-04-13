// WebSocketConnectionEventTracker.swift

import Foundation

actor WebSocketConnectionEventTracker {
    private struct Entry {
        var result: Result<Void, Swift.Error>?
        var waitersByIdentifier: [UUID: CheckedContinuation<Void, Swift.Error>] = .init()
    }

    private var entriesByTaskIdentifier: [Int: Entry] = .init()

    func beginTracking(taskIdentifier: Int) {
        stopTracking(taskIdentifier: taskIdentifier)
        entriesByTaskIdentifier[taskIdentifier] = .init()
    }

    func stopTracking(taskIdentifier: Int) {
        guard let entry = entriesByTaskIdentifier.removeValue(forKey: taskIdentifier) else { return }
        for continuation in entry.waitersByIdentifier.values {
            continuation.resume(throwing: CancellationError())
        }
    }

    func waitForOpen(taskIdentifier: Int) async throws {
        let waiterIdentifier = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Void, Swift.Error>) in
                guard var entry = entriesByTaskIdentifier[taskIdentifier] else {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                if let result = entry.result {
                    continuation.resume(with: result)
                    return
                }

                entry.waitersByIdentifier[waiterIdentifier] = continuation
                entriesByTaskIdentifier[taskIdentifier] = entry
            }
        } onCancel: {
            Task {
                await self.cancelWaiter(
                    taskIdentifier: taskIdentifier,
                    waiterIdentifier: waiterIdentifier
                )
            }
        }
    }

    func recordOpen(taskIdentifier: Int) {
        resolve(taskIdentifier: taskIdentifier, with: .success(()))
    }

    func recordFailure(taskIdentifier: Int, error: Swift.Error) {
        resolve(taskIdentifier: taskIdentifier, with: .failure(error))
    }

    private func cancelWaiter(taskIdentifier: Int, waiterIdentifier: UUID) {
        guard var entry = entriesByTaskIdentifier[taskIdentifier],
              let continuation = entry.waitersByIdentifier.removeValue(forKey: waiterIdentifier) else {
            return
        }

        entriesByTaskIdentifier[taskIdentifier] = entry
        continuation.resume(throwing: CancellationError())
    }

    private func resolve(taskIdentifier: Int, with result: Result<Void, Swift.Error>) {
        guard var entry = entriesByTaskIdentifier[taskIdentifier],
              entry.result == nil else {
            return
        }

        entry.result = result
        let waiters = entry.waitersByIdentifier.values
        entry.waitersByIdentifier.removeAll(keepingCapacity: false)
        entriesByTaskIdentifier[taskIdentifier] = entry

        for continuation in waiters {
            continuation.resume(with: result)
        }
    }
}
