// ClientHeartbeatValidator+TaskCompletionState.swift

import Foundation

extension ClientHeartbeatValidator {
    actor TaskCompletionState {
        private var completed = false

        func markCompleted() {
            completed = true
        }

        var isCompleted: Bool {
            completed
        }
    }
}
