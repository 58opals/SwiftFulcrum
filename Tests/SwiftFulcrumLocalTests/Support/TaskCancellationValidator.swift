// TaskCancellationValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct TaskCancellationValidator {
    @Test("cancellable value supports Never-failing tasks")
    func cancelWaiterWithoutCancellingNeverFailingTask() async {
        let underlyingTask = Task<Int, Never> {
            try? await Task.sleep(for: .seconds(30))
            return 42
        }
        let waiterTask = Task {
            try await underlyingTask.awaitCancellableValue(
                cancelUnderlyingTask: false
            )
        }

        waiterTask.cancel()
        await #expect(throws: CancellationError.self) {
            try await waiterTask.value
        }
        #expect(underlyingTask.isCancelled == false)

        underlyingTask.cancel()
        _ = await underlyingTask.value
    }
}
