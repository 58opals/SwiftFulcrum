// CancellableTaskWaitState.swift

import Synchronization

final class CancellableTaskWaitState<Success: Sendable>: Sendable {
    private typealias Storage = (
        continuation: CheckedContinuation<Success, Swift.Error>?,
        result: Result<Success, Swift.Error>?
    )

    private let storage = Mutex<Storage>((continuation: nil, result: nil))

    func install(_ continuation: CheckedContinuation<Success, Swift.Error>) {
        let result: Result<Success, Swift.Error>? = storage.withLock { storage in
            if let storedResult = storage.result {
                return storedResult
            }

            storage.continuation = continuation
            return nil
        }

        if let result {
            resume(continuation, with: result)
        }
    }

    func resolve(_ result: sending Result<Success, Swift.Error>) {
        let continuation: CheckedContinuation<Success, Swift.Error>? = storage.withLock { storage in
            guard storage.result == nil else {
                return nil
            }

            storage.result = result
            let continuation = storage.continuation
            storage.continuation = nil
            return continuation
        }

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
