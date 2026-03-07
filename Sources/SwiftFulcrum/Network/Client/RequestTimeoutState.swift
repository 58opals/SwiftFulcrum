// RequestTimeoutState.swift

import Foundation

actor RequestTimeoutState {
    private(set) var timeoutError: SwiftFulcrum.Client.Error?

    func mark(_ error: SwiftFulcrum.Client.Error) {
        timeoutError = error
    }
}
