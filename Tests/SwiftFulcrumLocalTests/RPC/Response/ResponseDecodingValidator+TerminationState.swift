// ResponseDecodingValidator+TerminationState.swift

import Foundation

extension ResponseDecodingValidator {
    actor TerminationState {
        private(set) var isTerminated = false

        func markTerminated() {
            isTerminated = true
        }
    }
}
