// SharedTaskCancellationCoordinator.swift

import Synchronization

final class SharedTaskCancellationCoordinator: Sendable {
    private let waiterCount = Mutex(0)

    func addWaiter() {
        waiterCount.withLock { count in
            count += 1
        }
    }

    @discardableResult
    func removeWaiter() -> Int {
        waiterCount.withLock { count in
            count -= 1
            return count
        }
    }

    var shouldCancelUnderlyingTaskForCancellingWaiter: Bool {
        waiterCount.withLock { count in
            count <= 1
        }
    }
}
