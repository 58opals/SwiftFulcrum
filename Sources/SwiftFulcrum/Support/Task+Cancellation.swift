// Task+Cancellation.swift

import Foundation

extension Task where Success: Sendable {
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
            switch await self.result {
            case .success(let value):
                waitState.resolve(.success(value))
            case .failure(let error):
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
