// WebSocketConnection.Lifecycle+Event.swift

import Foundation

extension WebSocketConnection.Lifecycle {
    enum Event: Sendable {
        case connected(isReconnect: Bool)
        case disconnected(code: URLSessionWebSocketTask.CloseCode, reason: String?)
    }
}
