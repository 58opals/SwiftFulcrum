// Task~Cancellation.swift

import Foundation

func awaitCancellableTask<Success: Sendable>(
    _ task: Task<Success, Swift.Error>,
    cancelUnderlyingTask: Bool = true
) async throws -> Success {
    try await awaitCancellableTask(
        task,
        shouldCancelUnderlyingTask: { cancelUnderlyingTask }
    )
}

func awaitCancellableTask<Success: Sendable>(
    _ task: Task<Success, Swift.Error>,
    shouldCancelUnderlyingTask: @escaping @Sendable () -> Bool
) async throws -> Success {
    if Task.isCancelled {
        if shouldCancelUnderlyingTask() {
            task.cancel()
        }
        throw CancellationError()
    }

    let waitState = CancellableTaskWaitState<Success>()
    Task {
        do {
            let value = try await task.value
            waitState.resolve(.success(value))
        } catch {
            waitState.resolve(.failure(error))
        }
    }

    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
            if Task.isCancelled {
                if shouldCancelUnderlyingTask() {
                    task.cancel()
                }
                continuation.resume(throwing: CancellationError())
            } else {
                waitState.install(continuation)
            }
        }
    } onCancel: {
        if shouldCancelUnderlyingTask() {
            task.cancel()
        }
        waitState.resolve(.failure(CancellationError()))
    }
}

final class SharedTaskCancellationCoordinator: @unchecked Sendable {
    private let lock = NSLock()
    private var waiterCount = 0

    func addWaiter() {
        lock.lock()
        waiterCount += 1
        lock.unlock()
    }

    @discardableResult
    func removeWaiter() -> Int {
        lock.lock()
        waiterCount -= 1
        let remainingCount = waiterCount
        lock.unlock()
        return remainingCount
    }

    var shouldCancelUnderlyingTaskForCancellingWaiter: Bool {
        lock.lock()
        let shouldCancel = waiterCount <= 1
        lock.unlock()
        return shouldCancel
    }
}

private final class CancellableTaskWaitState<Success>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Success, Swift.Error>?
    private var result: Result<Success, Swift.Error>?

    func install(_ continuation: CheckedContinuation<Success, Swift.Error>) {
        let result: Result<Success, Swift.Error>?

        lock.lock()
        if let storedResult = self.result {
            result = storedResult
        } else {
            self.continuation = continuation
            result = nil
        }
        lock.unlock()

        if let result {
            resume(continuation, with: result)
        }
    }

    func resolve(_ result: sending Result<Success, Swift.Error>) {
        let continuation: CheckedContinuation<Success, Swift.Error>?

        lock.lock()
        if self.result == nil {
            self.result = result
            continuation = self.continuation
            self.continuation = nil
        } else {
            continuation = nil
        }
        lock.unlock()

        if let continuation {
            resume(continuation, with: result)
        }
    }

    private func resume(
        _ continuation: CheckedContinuation<Success, Swift.Error>,
        with result: sending Result<Success, Swift.Error>
    ) {
        switch result {
        case .success(let value):
            continuation.resume(returning: value)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
