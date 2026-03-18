// TransportTestActor~Configuration.swift

import Foundation
@testable import SwiftFulcrum

extension TransportTestActor {
    func configureReconnectFailure(_ error: Swift.Error?) {
        reconnectFailure = error
    }

    func configureOutgoingSendDelay(_ delay: Duration?) {
        outgoingSendDelay = delay
    }

    func configureOutgoingSendPaused(_ isPaused: Bool) {
        shouldPauseOutgoingSend = isPaused
        if !isPaused {
            resumePendingOutgoingSends()
        }
    }

    func configureOutgoingSendFailure(_ error: Swift.Error?, forMethodPath methodPath: String) {
        if let error {
            outgoingSendFailuresByMethodPath[methodPath] = error
        } else {
            outgoingSendFailuresByMethodPath.removeValue(forKey: methodPath)
        }
    }

    func configureConnectDelay(_ delay: Duration?) {
        connectDelay = delay
    }

    func makeReconnectAttempts() -> Int {
        reconnectAttempts
    }

    func makePendingOutgoingSendCount() -> Int {
        pendingOutgoingSendGateContinuations.count
    }
}
