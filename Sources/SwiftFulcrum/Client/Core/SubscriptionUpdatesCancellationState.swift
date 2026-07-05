// SubscriptionUpdatesCancellationState.swift

import Foundation
import Synchronization

final class SubscriptionUpdatesCancellationState: Sendable {
    private let cancellationAction: @Sendable () async -> Void
    private let cancellationState = Mutex(false)

    init(cancellationAction: @escaping @Sendable () async -> Void) {
        self.cancellationAction = cancellationAction
    }

    func cancel() async {
        guard markCancelled() else { return }
        await cancellationAction()
    }

    deinit {
        guard markCancelled() else { return }
        let cancellationAction = cancellationAction
        Task {
            await cancellationAction()
        }
    }

    private func markCancelled() -> Bool {
        cancellationState.withLock { isCancelled in
            guard !isCancelled else { return false }
            isCancelled = true
            return true
        }
    }
}
