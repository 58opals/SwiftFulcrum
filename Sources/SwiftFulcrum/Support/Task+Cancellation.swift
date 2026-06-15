// Task+Cancellation.swift

import Foundation

extension Task where Failure == Swift.Error, Success: Sendable {
    func awaitCancellableValue(
        cancelUnderlyingTask: Bool = true
    ) async throws -> Success {
        try await awaitCancellableValue(
            shouldCancelUnderlyingTask: { cancelUnderlyingTask }
        )
    }

    func awaitCancellableValue(
        shouldCancelUnderlyingTask: @escaping @Sendable () -> Bool
    ) async throws -> Success {
        if Task<Never, Never>.isCancelled {
            if shouldCancelUnderlyingTask() {
                cancel()
            }
            throw Swift.CancellationError()
        }

        let waitState = CancellableTaskWaitState<Success>()
        _ = Task<Void, Never> {
            do {
                let value = try await self.value
                waitState.resolve(.success(value))
            } catch {
                waitState.resolve(.failure(error))
            }
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                if Task<Never, Never>.isCancelled {
                    if shouldCancelUnderlyingTask() {
                        cancel()
                    }
                    continuation.resume(throwing: Swift.CancellationError())
                } else {
                    waitState.install(continuation)
                }
            }
        } onCancel: {
            if shouldCancelUnderlyingTask() {
                cancel()
            }
            waitState.resolve(.failure(Swift.CancellationError()))
        }
    }
}
