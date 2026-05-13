// WebSocketReconnectorValidator+ReconnectStateProbe.swift

import Foundation
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    actor ReconnectStateProbe {
        private var states: [WebSocketConnection.ConnectionState] = .init()

        func record(_ state: WebSocketConnection.ConnectionState) {
            states.append(state)
        }

        func read() -> [WebSocketConnection.ConnectionState] { states }
    }
}
