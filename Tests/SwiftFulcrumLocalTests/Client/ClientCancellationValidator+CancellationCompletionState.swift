// ClientCancellationValidator+CancellationCompletionState.swift

import Foundation
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    actor CancellationCompletionState {
        private var completed = false
        private var error: SwiftFulcrum.Client.Error?
        private var completionCount = 0

        func finish(with error: SwiftFulcrum.Client.Error) {
            completed = true
            self.error = error
            completionCount += 1
        }

        var isCompleted: Bool {
            completed
        }

        var recordedError: SwiftFulcrum.Client.Error? {
            error
        }

        var count: Int {
            completionCount
        }
    }
}
