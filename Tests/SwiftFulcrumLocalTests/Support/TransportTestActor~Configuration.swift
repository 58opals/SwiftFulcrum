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

    func configureConnectDelay(_ delay: Duration?) {
        connectDelay = delay
    }

    func makeReconnectAttempts() -> Int {
        reconnectAttempts
    }
}
