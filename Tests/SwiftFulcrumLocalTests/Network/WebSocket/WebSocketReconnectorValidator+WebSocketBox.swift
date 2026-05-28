// WebSocketReconnectorValidator+WebSocketBox.swift

import Foundation
@testable import SwiftFulcrum

extension WebSocketReconnectorValidator {
    actor WebSocketBox {
        private var webSocket: WebSocketConnection?

        func store(_ webSocket: WebSocketConnection) {
            self.webSocket = webSocket
        }

        func makeConnectionState() async -> WebSocketConnection.ConnectionState? {
            guard let webSocket else { return nil }
            return await webSocket.connectionState
        }
    }
}
