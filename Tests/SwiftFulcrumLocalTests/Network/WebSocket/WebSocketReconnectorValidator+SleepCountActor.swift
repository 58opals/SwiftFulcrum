// WebSocketReconnectorValidator+SleepCountActor.swift

import Foundation
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    actor SleepCountActor {
        private var value = 0

        func increment() {
            value += 1
        }

        func reset() {
            value = 0
        }

        func read() -> Int { value }
    }

    actor ReconnectStateProbe {
        private var states: [WebSocketConnection.ConnectionState] = .init()

        func record(_ state: WebSocketConnection.ConnectionState) {
            states.append(state)
        }

        func read() -> [WebSocketConnection.ConnectionState] { states }
    }

    actor WebSocketBox {
        private var webSocket: WebSocketConnection?

        func set(_ webSocket: WebSocketConnection) {
            self.webSocket = webSocket
        }

        func connectionState() async -> WebSocketConnection.ConnectionState? {
            guard let webSocket else { return nil }
            return await webSocket.connectionState
        }
    }
}
